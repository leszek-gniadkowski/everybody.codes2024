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
go
create table dbo.input_text(id int,val varchar(8000))
create table dbo.input_textmax(id int,val varchar(max))
create table dbo.input_int(id int,val int)
create clustered index text_id on dbo.input_text(id)
create clustered index text_id on dbo.input_textmax(id)
create clustered index int_id on dbo.input_int(id)
create nonclustered index text_text on dbo.input_text(val)
create nonclustered index int_int on dbo.input_int(val)
go
-------------------------------------------------------------------------------------------------------

declare @input varchar(max)

set @input=''

set @input=replace(@input,char(10),'')

insert into dbo.input_text(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)

insert into dbo.input_textmax(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)

insert into dbo.input_int(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)
where TRY_CAST(Value as int) is not null

select len(@input) as len, max(len(val)) as row_maxlen, min(len(val)) as row_minlen from  dbo.input_textmax
select top(5) * from dbo.input_textmax order by id desc
select top(5) * from dbo.input_int order by id desc