use test

drop table if exists dbo.tally
go
create table dbo.tally(n int)
create clustered index text_id on dbo.tally(n)
insert into dbo.tally(n)
select value from generate_series(0,100000,1)
go
drop table if exists dbo.input_text
drop table if exists dbo.input_textmax
drop table if exists dbo.input_int
drop table if exists dbo.input_words
go
create table dbo.input_text(id int,val varchar(8000))
create table dbo.input_textmax(id int,val varchar(max))
create table dbo.input_int(id int,val int)
create table dbo.input_words(id int,val varchar(max))
create clustered index text_id on dbo.input_text(id)
create clustered index text_id on dbo.input_textmax(id)
create clustered index int_id on dbo.input_int(id)
create nonclustered index text_text on dbo.input_text(val)
create nonclustered index int_int on dbo.input_int(val)
go
-------------------------------------------------------------------------------------------------------

declare @input varchar(max)

set @input='WORDS:LOR,LL,SI,OR,CU,UR,AD

LOREM IPSUM DOLOR SIT AMET, CONSECTETUR ADIPISCING ELIT, SED DO EIUSMOD TEMPOR INCIDIDUNT UT LABORE ET DOLORE MAGNA ALIQUA. UT ENIM AD MINIM VENIAM, QUIS NOSTRUD EXERCITATION ULLAMCO LABORIS NISI UT ALIQUIP EX EA COMMODO CONSEQUAT. DUIS AUTE IRURE DOLOR IN REPREHENDERIT IN VOLUPTATE VELIT ESSE CILLUM DOLORE EU FUGIAT NULLA PARIATUR. EXCEPTEUR SINT OCCAECAT CUPIDATAT NON PROIDENT, SUNT IN CULPA QUI OFFICIA DESERUNT MOLLIT ANIM ID EST LABORUM.'

set @input=replace(@input,char(10),'')

insert into dbo.input_text(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)

insert into dbo.input_textmax(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)
where Value not like('words:%') and Value > ''

insert into dbo.input_words(id,val)
select ordinal,Value FROM string_split(
	(
		select stuff(Value,1,6,'') FROM string_split(@input,char(13),1)
		where Value like('WORDS:%')
	)
	,',',1)

insert into dbo.input_int(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)
where TRY_CAST(Value as int) is not null

---

select count(1) result 
from dbo.input_textmax txt
inner join dbo.tally tally
  on tally.n < len(txt.val)
inner join dbo.input_words words
  on substring(txt.val, 1 + tally.n, len(txt.val)) like(words.val + '%')