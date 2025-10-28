create database creditrisk;

use creditrisk;

SELECT count(*) FROM credit_risk_dataset_tt			-- hier habe ich erstmal kontrolliert wieviele Zeilen in der Spalte 
where loan_int_rate = '0' and loan_grade = '';		-- loan_int_rate leere Werte haben bei loan_grade A. Das habe ich dann für jede
													-- Kategorie so gemacht, darum habe ich mich dafür entschieden den Ø-Wert für
													-- jede Kategorie einzeln zu berechnen und bei den fehlenden Werten in der Spalte
													-- loan_int_rate einzusetzen.

update credit_risk_dataset_tt						-- zunächst habe ich alle leeren Werte mit 0 ersetzt
set loan_int_rate = 0
where loan_int_rate = '';

alter table credit_risk_dataset_tt					-- jetzt habe ich die Spalte loan_int_rate in den Typ Dezimal umgestellt
modify column loan_int_rate decimal(10,2);

select avg(loan_int_rate)							-- hiermit habe ich den Mittelwert bestimmt und fülle alle 0-Werte mit dem 
from credit_risk_dataset_tt							-- jeweiligen Mittelwert
where loan_grade = 'a' and loan_int_rate != 0;		-- habe alle Nullwerte mit dem jeweiligen Mittelwert ersetzt von A-G
											
start transaction;

update credit_risk_dataset_tt
set loan_int_rate = 10.99
where loan_grade = 'b' and loan_int_rate = 0;

select loan_int_rate from credit_risk_dataset_tt where loan_grade = 'c';

rollback;
commit;
alter table credit_risk_dataset_tt
add column id int auto_increment primary key;

create or replace view Altersgruppen as				 
select	id,											
	case
		when person_age between 20 and 24 then '20-24'
        when person_age between 25 and 34 then '25-34'
        when person_age between 35 and 44 then '35-44'
        when person_age between 45 and 54 then '45-54'
        else '55+'
	end as Altersgruppe
from credit_risk_dataset_tt;

SELECT *  FROM credit_risk_dataset_tt
where person_emp_length = 0 limit 35000;

select loan_int_rate from credit_risk_dataset_tt limit 35000;
alter table credit_risk_dataset_tt;				

alter table credit_risk_dataset_tt					-- jetzt habe ich die Spalte person_emp_length in den Typ Dezimal umgestellt
modify column person_emp_length decimal(5,2);

alter table credit_risk_dataset_tt					-- jetzt habe ich die Spalte person_income in den Typ Dezimal umgestellt,
modify column person_income decimal(10,2);			-- es war double vorher
    
select Altersgruppe,
	count(*) as Fallanzahl,							       -- hier habe ich versucht Auffälligkeiten je Altersgruppe herauszufinden, 
    round(avg(loan_amnt), 2) as Ø_Kredit,				   -- ob es ungewöhnliche Kombinationen gibt, z.B sehr hohe Maximalwerte bei
    max(loan_amnt) as max_Kredit,						   -- gleichzeitig niedrigem Durchschnittseinkommen
    round(avg(person_income), 2) as Ø_Einkommen,		   -- Mir ist dann aufgefallen, dass die durchschn. Berufserfahrung in allen 
    round(avg(person_emp_length), 2) as Ø_Berufserfahrung  -- Altersgruppen recht gleich ist.
from (
	select id,
		case 
			when person_age between 20 and 24 then '20-24'
            when person_age between 25 and 34 then '25-34'
            when person_age between 35 and 44 then '35-44'
            when person_age between 45 and 54 then '45-54'
            else '55+'
		end as Altersgruppe, loan_amnt, person_income, person_emp_length
	from credit_risk_dataset_tt) as sub
    group by Altersgruppe with rollup
    order by Altersgruppe;

select person_emp_length, count(*) as Anzahl		-- Darum wollte ich hiermit sehen wie die Verteilung aussieht
from credit_risk_dataset_tt							-- es gibt 2 Ausreisser, wobei die beiden Fälle mit 123 Jahre Betriebs- 
group by person_emp_length							-- zugehörigkeit fehlerhaft sein muss. Die Kreditnehmer sind 21 und 22 Jahre alt
order by person_emp_length;							-- da berechne ich den Mittelwert für das jeweilige Alter und ersetze es

select avg(person_emp_length)						-- die durchschn. Betriebszugehörigkeit ist 3.16, da hier nur in ganzen Jahren
from credit_risk_dataset_tt							-- eingetragen wird also 3 
where person_age = 22;

update credit_risk_dataset_tt
set person_emp_length = 3
where person_emp_length = 123;

select * 
from credit_risk_dataset_tt
where person_emp_length > 20;

create or replace view Betriebsstart as								-- view betriebsstart angelegt
select id, person_age, person_emp_length, person_income, 
loan_amnt, (person_age - person_emp_length) as Betriebsstart
from credit_risk_dataset_tt
where person_emp_length > 10
order by Betriebsstart;

select id, person_age, person_emp_length, person_income, 
loan_amnt, (person_age - person_emp_length) as Betriebsstart
from credit_risk_dataset_tt
where person_emp_length < 1 and loan_status =1
order by Betriebsstart;

select round(avg(c.person_income), 2) as Ø_Einkommen, a.Altersgruppe, 	-- Auffälligkeiten nach Altersgruppen im durschnittlichen 
round(avg(c.loan_amnt), 2) as Ø_Kredit, 								-- Verhältnis zum Einkommen, Kredithöhe, Beschäftigungszeit
round(avg(person_emp_length), 2) as Ø_Beschäftigungsdauer
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id 
group by a.Altersgruppe
order by a.Altersgruppe;

select person_age as 'Alter', loan_amnt as Kredithöhe, person_income as Einkommen 
from credit_risk_dataset_tt				-- mutmasslich gefälschtes Einkommen Seite 7
where person_age between 20 and 24
order by loan_amnt desc limit 20;

select count(*) as Anzahl, count(person_age) as '20-24', count(person_income) as über_39000
from credit_risk_dataset_tt										-- wieviele Fälle gibt es wo das Einkommen überØ hoch ist?
where person_age between 20 and 24 and person_income > 39000	-- Seite 7
group by person_age with rollup
order by person_age;

select a.Altersgruppe,										-- ich habe erstmal festgestellt, welche Altersgruppe prozentual
sum(loan_amnt) as Kreditvolumen,							-- am Gesamtkreditvolumen beteiligt ist
round(sum(loan_amnt) / (									-- es existiert ein totales Ungleichverhältnis, sehr bedenklich
select sum(loan_amnt)										-- Seite 5, fliesst in Ampel ein
from credit_risk_dataset_tt) * 100, 2) as Prozentanteil
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
group by a.Altersgruppe with rollup
order by a.Altersgruppe;

select loan_grade as Kreditklasse,							-- ich habe erstmal festgestellt, welche Kreditklasse prozentual
sum(loan_amnt) as Kreditvolumen,							-- am Gesamtkreditvolumen beteiligt ist
round(sum(loan_amnt) / (									
select sum(loan_amnt)										-- Seite 5, fliesst in die Ampel ein
from credit_risk_dataset_tt) * 100, 2) as Prozentanteil
from credit_risk_dataset_tt 
group by loan_grade with rollup
order by loan_grade;

select count(*) as säumige_Kunden							-- aus der Altersgruppe 20 bis 24 gibt es 2860 säumige Kunden.
from credit_risk_dataset_tt c								-- Seite 7
join altersgruppen a on a.id = c.id
where a.Altersgruppe = '20-24' and c.loan_status = 1 and person_income > 39000;

select count(*) as Kreditsäumnisse from credit_risk_dataset_tt where loan_status = 1;  -- es sind 7108 Kredite säumig

select a.Altersgruppe,														-- ich möchte die Säumigkeistrate ermitteln je nach
count(case when c.loan_status = 1 then 1 End) as Säumige,					-- Altersgruppe
count(*) as Gesamt,
round(count(case when c.loan_status = 1 then 1 End) / count(*) * 100,2
) as Säumigkeitsrate
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
group by Altersgruppe
order by Altersgruppe;

select a.Altersgruppe,													-- die Säumigkeitsrate verbunden mit Ø Beschäftigung,	
round(avg(c.person_emp_length), 2) as Ø_Beschäftigung,					-- Ø Einkommen und je nach Altersgruppe
round(avg(c.person_income), 2) as Ø_Einkommen,
count(case when c.loan_status = 1 then 1 End) as Säumige,
count(*) as Gesamt,
round(count(case when c.loan_status = 1 then 1 End) / count(*) * 100, 2
) as Säumigkeitsrate
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
group by Altersgruppe
having Säumigkeitsrate > 5
order by Altersgruppe;

create or replace view Anzahl_Zahlungsverzug as									-- view Anzahl_Zahlungsverzug
	select a.Altersgruppe,
    count(*) as Gesamtkunden,
    count(case when c.loan_status = 1 then 1 end) as Zahlungsverzug,
    round(count(case when c.loan_status = 1 then 1 end) / count(*) * 100, 2)
    as Zahlungsverzugsrate
    from credit_risk_dataset_tt c
    join altersgruppen a on a.id = c.id
    group by a.Altersgruppe
    order by a.Altersgruppe;

create or replace view frühere_Ausfälle as					-- frühere Ausfälle nach Altersgruppe, Seite 5, fliesst in Ampel ein
	select a.Altersgruppe,
    count(*) as Gesamtkunden,
    count(case when c.cb_person_default_on_file = 'Y' then 1 end) as früherer_Ausfall,
    round(count(case when c.cb_person_default_on_file = 'Y' then 1 end) / count(*) * 100, 2)
    as frühere_Ausfallrate
    from credit_risk_dataset_tt c
    join altersgruppen a on a.id = c.id
    group by a.Altersgruppe
    order by a.Altersgruppe;
    
   

create or replace view Kunden_ohne_Ausfall as					-- Kunden ohne Ausfall
	select a.Altersgruppe,
    count(*) as Gesamtkunden,
    count(case when c.loan_status = 0 and c.cb_person_default_on_file = 'N' then 1 end)
    as kein_Ausfall,
    round(count(case when c.loan_status = 0 and c.cb_person_default_on_file = 'N' then 1 end) / count(*) * 100, 2)
    as keine_Ausfallrate
    from credit_risk_dataset_tt c
    join altersgruppen a on a.id = c.id
    group by Altersgruppe
    order by a.Altersgruppe;

create or replace view Ø_Einkommen_und_Beschäftigung as			-- Ø Einkommen und Beschäftigung
	select a.Altersgruppe,
    round(avg(c.person_emp_length), 2) as Ø_Beschäftigung,
    round(avg(c.person_income), 2) as Ø_Einkommen
    from credit_risk_dataset_tt c
    join altersgruppen a on a.id = c.id
    group by a.Altersgruppe
    order by a.Altersgruppe;

select a.Altersgruppe, c.person_income as Einkommen, count(*) as Anzahl -- hier schaue ich mir die verteilung der 100 höchsten Einkommen an
from credit_risk_dataset_tt c							-- diese Abfrage zeigt deutlich, dass extrem hohe Einkommen nicht nur in 
join altersgruppen a on a.id = c.id						-- der Gruppe der 55+ vertreten sind, sondern auch in der Gruppe der 25-34jährigen,
group by c.person_income, a.Altersgruppe				-- was extrem unwahrscheinlich ist. // gefälschte Angaben? //
order by c.person_income desc limit 100;

select a.Altersgruppe as Altersgruppe,							-- hier habe ich mir den Anteil der überdurchschnittlichen
count(*) as Gesamtanzahl,										-- Einkommen je Altersgruppe angeschaut. Völlig utopisch
count(case when c.person_income > 58000 then 1 end)				-- im Bereich der 20- bis 24-jährigen.
as Anzahl_über_58000,
round(count(case when c.person_income > 58000 then 1 end) /
count(*) * 100, 2) as prozentualer_Anteil
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
group by a.Altersgruppe with rollup
order by a.Altersgruppe;

select c. loan_grade as Kreditklasse,			-- wie sieht die Verteilung der Kreditklasse am 
count(*) as Anzahl_über_58000,					-- Kreditvolumen bei einem Einkommen über 58000 USD aus.
round(count(*) / (
	select count(*)
    from credit_risk_dataset_tt c
    where c.person_income > 58000) * 100, 2) as Prozentanteil
from credit_risk_dataset_tt c
where c.person_income > 58000
	and c.loan_grade in ('A', 'B', 'C', 'D', 'E', 'F', 'G')
group by c.loan_grade with rollup
order by c.loan_grade;

select a.Altersgruppe as Altersgruppe,									-- hier stelle ich die vergangenheitswerte den aktuellen
count(*) as Gesamtkunden,												-- gegenüber. ca 20 % der Zahlungsschwierigkeiten hätte
sum(case when c.cb_person_default_on_file = 'Y' then 1 else 0 end		-- man sich sparen können.
) as vergangene_Ausfälle,
sum(case when c.loan_status = 1 then 1 End) as Säumig,
sum(case when c.cb_person_default_on_file != 'Y' and c.loan_status != 1 
then 1 else 0 end) as keine_Ausfälle,
round(sum(case when c.cb_person_default_on_file = 'Y' then 1 else 0 end) / 
count(*) * 100, 2) as vergangene_Ausfallrate,
round(sum(case when c.loan_status = 1 then 1 End) / count(*) * 100, 2)
as Säumigkeitsrate,
round(sum(case when c.cb_person_default_on_file != 'Y' and c.loan_status != 1 
then 1 else 0 end) / Count(*) * 100, 2) as keine_Ausfallrate
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
group by a.Altersgruppe with rollup
order by a.Altersgruppe;

create or replace view Kreditklasse as
select loan_grade, cb_person_default_on_file as Alt_Probleme, -- hier schaue ich mir den loan_grade zum Zinssatz an und berücksichtige 
round(avg(loan_int_rate), 2) as Ø_Zinssatz,					  -- dabei die Vergangenheitswerte.
count(*) as Anzahl											  
from credit_risk_dataset_tt
where loan_int_rate > 0
group by loan_grade, cb_person_default_on_file
order by loan_grade, cb_person_default_on_file;

select loan_grade, cb_person_default_on_file as Alt_Probleme,  
loan_status as Zahlungsverzug,
round(avg(loan_int_rate), 2) as Ø_Zinssatz,					  -- Zusätzlich möchte ich jetzt noch die aktuellen Zahlungsverzüge
count(*) as Anzahl											  -- anschauem.
from credit_risk_dataset_tt
where loan_int_rate > 0
group by loan_grade, cb_person_default_on_file, loan_status
order by loan_grade, cb_person_default_on_file, loan_status;

select loan_grade, cb_person_default_on_file as Alt_Probleme,  -- zusätzlich habe ich das Ø Einkommen je Gruppe hinzugefügt
loan_status as Zahlungsverzug,
round(avg(loan_int_rate), 2) as Ø_Zinssatz,					  
round(avg(person_income), 2) as Ø_Einkommen,				  
count(*) as Anzahl
from credit_risk_dataset_tt
where loan_int_rate > 0
group by loan_grade, cb_person_default_on_file, loan_status
order by loan_grade, cb_person_default_on_file, loan_status;

select c.loan_grade, c.cb_person_default_on_file as Alt_Probleme,  	
c.loan_status as Zahlungsverzug, a.Altersgruppe,					-- die Abfrage zeigt die Ergebnisse einer Zinsklassifizierung
round(avg(c.loan_int_rate), 2) as Ø_Zinssatz,						-- nach Ø-Einkommen, Ø-Zinssatz in Bezug auf früheren
round(avg(c.person_income), 2) as Ø_Einkommen,						-- Kreditausfällen und aktuellen Zahlungsausfällen.
count(*) as Anzahl
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
where c.loan_int_rate > 0
group by c.loan_grade, c.cb_person_default_on_file, c.loan_status, a.Altersgruppe
order by c.loan_grade, c.cb_person_default_on_file, c.loan_status, a.Altersgruppe;

create or replace view negativ_Klassifizierung_Altersgruppen as
select c.loan_grade as Zinsklasse, c.cb_person_default_on_file as Alt_Probleme,  	-- mit dieser Abfrage habe ich mir eine neue virtuelle Tabelle als
c.loan_status as Zahlungsverzug, a.Altersgruppe,					-- view erstellt. Sie zeigt die Ergebnisse einer Zinsklassifi-
round(avg(c.loan_int_rate), 2) as Ø_Zinssatz,						-- zierung nach Ø-Einkommen, Ø-Zinssatz, Ø-Kredithöhe in Bezug auf
round(avg(c.person_income), 2) as Ø_Einkommen,						-- früheren Kreditausfällen und aktuellen Zahlungsausfällen.
round(avg(c.loan_amnt), 2) as Ø_Kredithöhe,
count(*) as Anzahl
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
where c.loan_int_rate > 0 and c.cb_person_default_on_file = 'Y' and c.loan_status = 1
group by c.loan_grade, c.cb_person_default_on_file, c.loan_status, c.loan_amnt, a.Altersgruppe
order by c.loan_grade, c.cb_person_default_on_file, c.loan_status, c.loan_amnt, a.Altersgruppe;

create table klassifizierungsproblem_altersgruppen (
id int auto_increment primary key,
Altersgruppe varchar(10),
Kreditgrad char(1),
Altprobleme char(1),
Zahlungsverzug tinyint,
Ø_Zinssatz decimal(5,2),
Ø_Einkommen decimal(10,2),
Ø_Kredithöhe decimal(10,2),
Anzahl int);

alter table klassifizierungsproblem_altersgruppen
add column Ø_Beschäftigungsverhältnis decimal (4,1);

insert into klassifizierungsproblem_altersgruppen (
Altersgruppe, Kreditgrad, Altprobleme, Zahlungsverzug, Ø_Zinssatz,
Ø_Einkommen, Ø_Kredithöhe, Ø_Beschäftigungsverhältnis, Anzahl)
select
a.Altersgruppe, c.loan_grade, c.cb_person_default_on_file, c.loan_status,
round(avg(c.loan_int_rate), 2),
round(avg(c.person_income), 2),
round(avg(c.loan_amnt), 2),
round(avg(c.person_emp_length), 1), count(*)
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
where c.loan_int_rate > 0 
group by a.Altersgruppe, c.loan_grade, c.cb_person_default_on_file, c.loan_status, c.loan_amnt
order by a.Altersgruppe, c.loan_grade, c.cb_person_default_on_file, c.loan_status, c.loan_amnt;

select * from klassifizierungsproblem_altersgruppen
where Altersgruppe = '20-24' and Zahlungsverzug = 1 and Ø_Beschäftigungsverhältnis < 3
order by Ø_Beschäftigungsverhältnis;

select Count(*) as Anzahl, loan_grade as Kreditklasse, person_emp_length as Beschäftigungszeit
from credit_risk_dataset_tt
where person_emp_length < 1 and loan_status = 1
group by loan_grade, person_emp_length
order by loan_grade;

create or replace view positiv_Klassifizierung_Altersgruppen as
select c.loan_grade as Zinsklasse, c.cb_person_default_on_file as Alt_Probleme,  	-- mit dieser Abfrage habe ich mir eine neue virtuelle Tabelle als
c.loan_status as Zahlungsverzug, a.Altersgruppe,					-- view erstellt. Sie zeigt die Ergebnisse einer Zinsklassifi-
round(avg(c.loan_int_rate), 2) as Ø_Zinssatz,						-- zierung nach Ø-Einkommen, Ø-Zinssatz, Ø-Kredithöhe in Bezug auf
round(avg(c.person_income), 2) as Ø_Einkommen,						-- früheren Kreditausfällen und aktuellen Zahlungsausfällen.
round(avg(c.loan_amnt), 2) as Ø_Kredithöhe,
count(*) as Anzahl
from credit_risk_dataset_tt c
join altersgruppen a on a.id = c.id
where c.loan_int_rate > 0 and c.cb_person_default_on_file = 'N' and loan_status = 0
group by c.loan_grade, c.cb_person_default_on_file, c.loan_status, c.loan_amnt, a.Altersgruppe
order by c.loan_grade, c.cb_person_default_on_file, c.loan_status, c.loan_amnt, a.Altersgruppe;

select person_income as Einkommen, person_home_ownership as Immobesitzer, loan_amnt as Kreditsumme	
from credit_risk_dataset_tt			-- unterscheidet sich die die Vergabestruktur wenn ich nach
where loan_intent ='Education'		-- Verwendungszweck selektiere? Nein
order by loan_intent;
select person_income as Einkommen, person_home_ownership as Immobesitzer, loan_amnt as Kreditsumme
from credit_risk_dataset_tt
where loan_intent ='Medical'
order by loan_intent;
select person_income as Einkommen, person_home_ownership as Immobesitzer, loan_amnt as Kreditsumme
from credit_risk_dataset_tt
where loan_intent ='Debtconsolidation'
order by loan_intent;
select person_income as Einkommen, person_home_ownership as Immobesitzer, loan_amnt as Kreditsumme
from credit_risk_dataset_tt
where loan_intent ='Venture'
order by loan_intent;
select person_income as Einkommen, person_home_ownership as Immobesitzer, loan_amnt as Kreditsumme
from credit_risk_dataset_tt
where loan_intent ='Homeimprovement'
order by loan_intent;
select person_income as Einkommen, person_home_ownership as Immobesitzer, loan_amnt as Kreditsumme
from credit_risk_dataset_tt
where loan_intent ='Personal';

select loan_intent as Verwendungszweck,  -- die Ø-Werte unterscheiden sich nicht bezogen auf den Verwendungszweck
round(avg(person_income), 2) as Ø_Einkommen,
round(avg(loan_amnt), 2) as Ø_Kreditsumme,
round(avg(loan_int_rate), 2) as Ø_Zinssatz,
count(*) as Anzahl
from credit_risk_dataset_tt
group by loan_intent
order by loan_intent; 

select loan_grade as Kreditklasse,  -- die Ø-Werte unterscheiden sich nicht bezogen auf den 
round(avg(person_income), 2) as Ø_Einkommen,
round(avg(loan_amnt), 2) as Ø_Kreditsumme,
round(avg(loan_int_rate), 2) as Ø_Zinssatz,
count(*) as Anzahl
from credit_risk_dataset_tt
group by loan_grade
order by loan_grade; 

create or replace view Kreditklasse_Verwendungszweck as				-- keine nennenswerte Auffälligkeiten
select loan_intent as Verwendungszweck, loan_grade as Krediklasse, 
round(avg(loan_int_rate), 2) as Ø_Zinssatz,
count(*) as Anzahl
from credit_risk_dataset_tt
group by loan_intent, loan_grade
order by loan_intent, loan_grade;

select loan_grade as Kreditklasse,
min(loan_int_rate) as Min_Zinssatz,
max(loan_int_rate) as Max_Zinssatz,
round(avg(loan_int_rate), 2) as Ø_Zinssatz,
count(*) as Anzahl
from credit_risk_dataset_tt
where loan_int_rate > 0
group by loan_grade
order by loan_grade;

select loan_grade as Kreditklasse,			-- Zahlungsverzüge nach Kreditklasse und deren prozentualen Anteil in den 
count(*) as Anzahl_Kredite,					-- Kreditklassen ( Kreditklassen mit Ausfallraten) Seite 5
round(avg(person_emp_length), 2) as Ø_Beschäftigung,
sum(case 									-- zusätzlich habe ich den Ausfall aus der Historie dazugeholt
		when loan_status = 1 then 1 
        else 0 
        end) as Anzahl_Zahlungsverzug,
round(sum(case
			when loan_status = 1 then 1 
            else 0
            end) / count(*) * 100, 2) as Verzugsrate,
sum( case
		when cb_person_default_on_file = 'Y' then 1
		else 0
        end) as Anzahl_Ausfall,
 round(sum( case
 			when cb_person_default_on_file = 'Y' then 1
            else 0
            end) / count(*) * 100, 2) as Ausfallrate
from credit_risk_dataset_tt
group by loan_grade
order by loan_grade;

 select a.Altersgruppe, count(*) as Anzahl_Verzugsrate		-- Hier habe ich mir Kreditklasse C genauer angesehen, um festzu-
    from altersgruppen a									-- welche Altersklassen meistens im Verzug sind.
    join credit_risk_dataset_tt c on c.id = a.id			-- Das gleiche mache ich mit Kreditklasse B
    where c.loan_grade = 'C'								-- Seite 5
    and c.loan_status = 1
    group by a.Altersgruppe with rollup
    order by a.Altersgruppe;
    
    select a.Altersgruppe, count(*) as Anzahl_Verzugsrate		-- Hier habe ich mir Kreditklasse B genauer angesehen, um festzu-
    from altersgruppen a									-- welche Altersklassen meistens im Verzug sind.
    join credit_risk_dataset_tt c on c.id = a.id			-- Seite 5
    where c.loan_grade = 'B'
    and c.loan_status = 1
    group by a.Altersgruppe with rollup
    order by a.Altersgruppe;

select * from credit_risk_dataset_tt where loan_grade = 'G';

select person_income as Einkommen, loan_amnt as Kreditsumme -- zeigt den einzigen positiven Fall in Kreditklasse G
from credit_risk_dataset_tt									
where loan_grade = 'G' and loan_status = 0;
    
select count(*) as Anzahl_historischer_Ausfall	-- Anzahl an Kreditvergaben an Kunden, die vorher schon einen Ausfall hatten
from credit_risk_dataset_tt c					-- Seite 7
join altersgruppen a on a.id = c.id
where c.cb_person_default_on_file = 'Y' and a.Altersgruppe = '20-24';

select loan_grade as Kreditklasse,			-- Anzahl an Krediten je Kreditklasse
count(*) as Anzahl_Kredite					-- 
from credit_risk_dataset_tt
group by loan_grade with rollup
order by loan_grade;

select loan_grade as Kreditklasse,			-- in welchen Kreditklassen gab es vor der Kreditaufnahme Kreditausfälle?
count(*) as Anzahl_Kreditausfall_alt
from credit_risk_dataset_tt
where cb_person_default_on_file = 'Y'
group by loan_grade
order by loan_grade;

select count(*) as Anzahl, loan_grade as Kreditklasse,  -- Untersuchung der Zahlungsverzüge im Verhältnis zu den 
round(avg(loan_amnt), 2) as Ø_Kreditsumme,				-- Neubeschäftigten, die unter ein Jahr beschäftigt sind
sum(case 
		when loan_status = 1 then 1
        else 0
        end) as Anzahl_Zahlungsverzug
from credit_risk_dataset_tt
where person_emp_length = 0
group by loan_grade with rollup
order by loan_grade;

select count(*) as Anzahl, loan_grade as Kreditklasse,  -- Untersuchung der Zahlungsverzüge im Verhältnis zu dem 
round(avg(loan_amnt), 2) as Ø_Kreditsumme,				-- Verschuldungsgrad, die unter ein Jahr beschäftigt sind
sum(case 
		when loan_percent_income > 0.20 then 1
        else 0
        end) as 'Verschuldungsgrad > 20%'
from credit_risk_dataset_tt
where person_emp_length = 0
group by loan_grade with rollup
order by loan_grade;

select 																-- Kreditanzahl pro Verschuldungsquote, hiermit erkenne ich
case																-- ab welchem Verschuldungsniveau das Risiko steigt.
	when loan_percent_income < 0.1 then '<10 %'						-- Seite 7
    when loan_percent_income between 0.1 and 0.19 then '10-19 %'
    when loan_percent_income between 0.2 and 0.29 then '20-29 %'
    when loan_percent_income between 0.3 and 0.39 then '30-39 %'
    when loan_percent_income between 0.4 and 0.49 then '40-49 %'
    when loan_percent_income between 0.5 and 0.59 then '50-59 %'
    when loan_percent_income between 0.6 and 0.69 then '60-69 %'
    when loan_percent_income between 0.7 and 0.79 then '70-79 %'
    else '80+ %'
    end as Verschuldungsquote,
count(*) as Gesamtanzahl,
sum(case when loan_status = 1 then 1 else 0 end) as Zahlungsausfälle,
round(sum(case when loan_status = 1 then 1 else 0 end) * 100 /
count(*), 2) as Ausfallquote
from credit_risk_dataset_tt
group by Verschuldungsquote with rollup
order by min(loan_percent_income);

select loan_grade as Kreditklasse,
min(loan_int_rate) as Min_Zins,
max(loan_int_rate) as Max_Zins
from credit_risk_dataset_tt
group by loan_grade
order by loan_grade;

select 																-- Einkommensgruppe zum Ausfall
case																-- ab welcher Einkommensuntergrenze steigt das Risiko.
	when person_income < 20000 then '< 20000'						-- Seite 7
    when person_income between 20001 and 30000 then '20001-30000'
    when person_income between 30001 and 40000 then '30001-40000'
    when person_income between 40001 and 50000 then '40001-50000'
    when person_income between 50001 and 60000 then '50001-60000'
    when person_income between 60001 and 70000 then '60001-70000'
    when person_income between 70001 and 80000 then '70001-80000'
    when person_income between 80001 and 90000 then '80001-90000'
	when person_income between 90001 and 100000 then '90001-100000'
    when person_income between 100001 and 110000 then '100001-110000'
    when person_income between 110001 and 120000 then '110001-120000'
    else '120001+'
    end as Einkommensgruppe,
count(*) as Gesamtanzahl,
sum(case when loan_status = 1 then 1 else 0 end) as Zahlungsausfälle,
round(sum(case when loan_status = 1 then 1 else 0 end) * 100 /
count(*), 2) as Ausfallquote,
sum(case when cb_person_default_on_file = 'Y' then 1 else 0 end) as Hist_Ausfall,
round(sum(case when cb_person_default_on_file = 'Y' then 1 else 0 end) * 100 /
count(*), 2) as Hist_Ausfallquote
from credit_risk_dataset_tt
group by Einkommensgruppe with rollup
order by min(person_income);

select 												-- hier prüfe ich wieviele Zahlungsstörungen es gab nach Verwendungszweck		
case																
	when loan_intent = 'MEDICAL' then 'Med'						
    when loan_intent = 'personal' then 'Pers'
    when loan_intent = 'homeimprovement' then 'Homeimp'						
    when loan_intent = 'venture' then 'Vent'
    when loan_intent = 'education' then 'Educ'					
    when loan_intent = 'debtconsolidation' then 'Debtcon'
       else 'Divers'
    end as Verwendungszweck,
count(*) as Gesamtanzahl,
sum(case when loan_status = 1 then 1 else 0 end) as Zahlungsausfälle,
round(sum(case when loan_status = 1 then 1 else 0 end) * 100 /
count(*), 2) as Ausfallquote
from credit_risk_dataset_tt
group by loan_intent with rollup;

select 																
case																
	when loan_intent = 'MEDICAL' then 'Med'						
    when loan_intent = 'personal' then 'Pers'
    when loan_intent = 'homeimprovement' then 'Homeimp'						
    when loan_intent = 'venture' then 'Vent'
    when loan_intent = 'education' then 'Educ'					
    when loan_intent = 'debtconsolidation' then 'Debtcon'
       else 'Div'
    end as Verwendungszweck,
count(*) as Gesamtanzahl,
sum(case when cb_person_default_on_file = 'Y' then 1 else 0 end) as hist_Ausfall,
round(sum(case when cb_person_default_on_file = 'Y' then 1 else 0 end) * 100 /
count(*), 2) as hist_Ausfallquote
from credit_risk_dataset_tt
group by loan_intent with rollup;

select Beschäftigungsdauer,
count(*) as Gesamtanzahl,
sum(Zahlungsausfälle),
round(ifnull ( sum(Zahlungsausfälle) * 100 / count(*), 0), 2) as Ausfallquote
from (
	select                                                          -- Kreditanzahl Beschäftigungsdauer, hiermit erkenne ich
		case														-- ab welcher Einkommensgrenze das Risiko steigt.
			when person_emp_length < 1 then '<1'   					-- Seite 7
			when person_emp_length between 1 and 4 then '1-4'
			when person_emp_length between 4.1 and 7 then '4.1-7'
			when person_emp_length between 7.1 and 10 then '7.1-10'
			when person_emp_length between 10.1 and 13 then '10.1-13'
			when person_emp_length between 13.1 and 16 then '13.1-16'
			when person_emp_length between 16.1 and 20 then '16.1-20'
			else '20+'
		end as Beschäftigungsdauer,
		case when loan_status = 1 then 1 else 0 end as Zahlungsausfälle
	from credit_risk_dataset_tt) as sub
group by Beschäftigungsdauer with rollup
order by 
	case Beschäftigungsdauer
		when '<' then 1
        when '1-4' then 2
        when '4.1-7' then 3
        when '7.1-10' then 4
        when '10.1-13' then 5
        when '13.1-16' then 6
        when '16.1-20' then 7
        when '20+' then 8
        else 9
	end;



create view Risiko_Ampel as
select id as ID, loan_grade as Kreditklasse,				-- erste Ampel hergestellt
	case
		when cb_person_default_on_file = 'Y' then 'red' 
        else 'green' end as hist_Ausfall,
	case
       when loan_status = 1 then 'yellow' else 'green' end as Versäumnis,
	case
        when person_income < 20000 then 'red'
        when person_income between 20000 and 60000 then 'yellow'
        else 'green'
	end as Einkommenprüf,
    case
		when loan_intent = 'Debtconsolidation' then 'yellow'
        when loan_intent = 'Homeimprovement' then 'yellow'
        when loan_intent = 'Medical' then 'yellow'
        else 'green'
	end as Verwendungsprüf,
    case 
		when person_age between 20 and 44 then 'green'
        when person_age between 45 and 54 then 'yellow'
        else 'red' end as Alterprüf,
	case
		when loan_grade = 'A' then 'green'
        when loan_grade = 'B' then 'green'
        when loan_grade = 'C' then 'yellow'
        else 'red'
	end as Ratingprüf,
	case
		when loan_percent_income < 0.1 then 'green'
        when loan_percent_income between 10 and 29 then 'yellow'
        else 'red'
	end as Verschuldungsprüf
from credit_risk_dataset_tt;

 select
	case
		when Kreditklasse = 'red' or hist_Ausfall = 'red' or Versäumnis = 'red'
			or Einkommenprüf = 'red' or Verwendungsprüf = 'red' or Alterprüf = 'red'
			or Ratingprüf = 'red' or Verschuldungsprüf = 'red' then 'rot'
		when Kreditklasse = 'yellow' or hist_Ausfall = 'yellow' or Versäumnis = 'yellow'
			or Einkommenprüf = 'yellow' or Verwendungsprüf = 'yellow' or Alterprüf = 'yellow'
			or Ratingprüf = 'yellow' or Verschuldungsprüf = 'yellow' then 'gelb'
		else 'grün'
	end as Gesamtrisiko,			-- hier zähle ich alle rot-, gelb- und grün-Werte zusammen
    count(*) as Anzahl
from risiko_ampel
group by Gesamtrisiko
order by
	case Gesamtrisiko
		when 'rot' then 1
        when 'gelb' then 2
        else 3
	end;
    
    select ID, (
		(Kreditklasse = 'red') + (hist_Ausfall = 'red') + (Versäumnis = 'red') + (Einkommenprüf = 'red') + 
        (Verwendungsprüf = 'red') + (Alterprüf = 'red') + (Ratingprüf = 'red') + (Verschuldungsprüf = 'red'))
        as Anzahl_rot,
        ((Kreditklasse = 'yellow') + (hist_Ausfall = 'yellow') + (Versäumnis = 'yellow') + (Einkommenprüf = 'yellow') + 
        (Verwendungsprüf = 'yellow') + (Alterprüf = 'yellow') + (Ratingprüf = 'yellow') + (Verschuldungsprüf = 'yellow'))
        as Anzahl_gelb,
       ((Kreditklasse = 'green') + (hist_Ausfall = 'green') + (Versäumnis = 'green') + (Einkommenprüf = 'green') + 
        (Verwendungsprüf = 'green') + (Alterprüf = 'green') + (Ratingprüf = 'green') + (Verschuldungsprüf = 'green'))
        as Anzahl_grün		-- hier wird für jede Zeile zusammengezählt wieviele rot-, gelb- und grün-Werte vohanden sind
	from risiko_ampel;
    
create or replace view Risiko_Ampel_Gesamtrisiko as
    select ID, Kreditklasse, hist_Ausfall, Versäumnis, Einkommenprüf, Verwendungsprüf, Alterprüf,
    Ratingprüf, Verschuldungsprüf, (
   		(Kreditklasse = 'red') + (hist_Ausfall = 'red') + (Versäumnis = 'red') + (Einkommenprüf = 'red') + 
        (Verwendungsprüf = 'red') + (Alterprüf = 'red') + (Ratingprüf = 'red') + (Verschuldungsprüf = 'red'))
        as Anzahl_rot,
	case 
		when hist_Ausfall = 'red' then 'rot'
        when Versäumnis = 'red' then 'rot'
        when ((Kreditklasse = 'red') + (hist_Ausfall = 'red') + (Versäumnis = 'red') + (Einkommenprüf = 'red') + 
        (Verwendungsprüf = 'red') + (Alterprüf = 'red') + (Ratingprüf = 'red') + (Verschuldungsprüf = 'red'))
        >= 4 then 'rot'
        when ((Kreditklasse = 'red') + (hist_Ausfall = 'red') + (Versäumnis = 'red') + (Einkommenprüf = 'red') + 
        (Verwendungsprüf = 'red') + (Alterprüf = 'red') + (Ratingprüf = 'red') + (Verschuldungsprüf = 'red'))
        >= 1 then 'gelb'
        when 
		((Kreditklasse = 'yellow') + (hist_Ausfall = 'yellow') + (Versäumnis = 'yellow') + (Einkommenprüf = 'yellow') + 
        (Verwendungsprüf = 'yellow') + (Alterprüf = 'yellow') + (Ratingprüf = 'yellow') + (Verschuldungsprüf = 'yellow'))
        >= 1 then 'gelb'		-- Für das Gesamtrisiko gilt folgendes: wenn es mindestens 4 rote Kriterien gibt, bleibt es bei rot, ebenfalls 
        else 'grün'				-- wenn hist_Ausfall rot ist oder Versäumnis rot ist bleibt es immer rot, ansonsten wird es zu gelb und grün
	end as Gesamtrisiko   		-- bleibt immer grün.
from risiko_ampel;

select Gesamtrisiko, count(*) as Anzahl
from risiko_ampel_gesamtrisiko
group by Gesamtrisiko			-- hier habe ich Gesamtanzahl an Krediten, die die Kategorie grün, gelb oder rot haben
order by 
	case Gesamtrisiko
		when 'rot' then 1
        when 'gelb' then 2
        else 3
	end;
    
select Gesamtrisiko, count(*) as Anzahl 	-- jetzt fasse ich alle einzelnen Schritte zusammen, um eine einzige Abfrage zu erhalten
from (
	select ID, Kreditklasse, hist_Ausfall, Versäumnis, Einkommenprüf, Verwendungsprüf,
    Alterprüf, Ratingprüf, Verschuldungsprüf,
    (
		(Kreditklasse = 'red') + (hist_Ausfall = 'red') + (Versäumnis = 'red') + (Einkommenprüf = 'red') + 
        (Verwendungsprüf = 'red') + (Alterprüf = 'red') + (Ratingprüf = 'red') + (Verschuldungsprüf = 'red'))
        as Anzahl_rot,
	case
		when hist_Ausfall = 'red' then 'rot'
        when Versäumnis = 'red' then 'rot'
        when ((Kreditklasse = 'red') + (hist_Ausfall = 'red') + (Versäumnis = 'red') + (Einkommenprüf = 'red') + 
        (Verwendungsprüf = 'red') + (Alterprüf = 'red') + (Ratingprüf = 'red') + (Verschuldungsprüf = 'red'))
        >= 4 then 'rot'
        when ((Kreditklasse = 'red') + (hist_Ausfall = 'red') + (Versäumnis = 'red') + (Einkommenprüf = 'red') + 
        (Verwendungsprüf = 'red') + (Alterprüf = 'red') + (Ratingprüf = 'red') + (Verschuldungsprüf = 'red'))
        >= 1 then 'gelb'
        when ((Kreditklasse = 'yellow') + (hist_Ausfall = 'yellow') + (Versäumnis = 'yellow') + (Einkommenprüf = 'yellow') + 
        (Verwendungsprüf = 'yellow') + (Alterprüf = 'yellow') + (Ratingprüf = 'yellow') + (Verschuldungsprüf = 'yellow'))
        >= 1 then 'gelb'
        else 'grün'
	end as Gesamtrisiko
from risiko_ampel) as Bewertungsrisiko
group by Gesamtrisiko
order by 
	case Gesamtrisiko
		when 'rot' then 1
        when 'gelb' then 2
        else 3
	end;
    
select gesamtrisiko, Anzahl_rot     -- ein letzter Test ob die Ampel funktioniert, denn es dürfen keine  grün-Werte angezeigt werden
from risiko_ampel_gesamtrisiko
where anzahl_rot > 0 and Gesamtrisiko = 'grün';   

select count(*)
from risiko_ampel_gesamtrisiko
where Gesamtrisiko != 'rot' and Versäumnis = 'yellow' ;

select count(*)
from credit_risk_dataset_tt
where cb_person_default_on_file = 'Y';