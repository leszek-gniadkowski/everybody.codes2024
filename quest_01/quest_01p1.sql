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

set @input='CBACCCCCCCCCCBCCBAACBBCCABBCAAAABBCAAAABCCCCAABBCAACBCCAACAAACBCCAAABAAACBAACBACAABAACCCBCCCCBCABAAAAAACACBABBBBCABBABCCCABABCCBBCBCCABBCCABAAACBCAACBBBCACCBBAACABBCCCCCAABACCAABABAAABBCACBACCBCCBABBCCBABABBAACACCACCCBABCBABACCCCAABACCCBABCCBCCABACABBBBCCBBBBBBCCCABAAACCBACCBCBBBBACAABBCBBCAABACCCAABCCAACABCCBACBCBCBCBCACBBCAACBABCBAABAABCBBCABAAACAAACCBCBAAACBABACCCABBBCCCCCCCAAACBBBAABABACABABABCBCAAABBCCBCBBBBBCACCCCBBBCBBAAACBACCABCCCBCCCCCCBCBAABCCABBBBCCACCCCBCACABACAAACAAAABBBBABACCBBBCCCAABBBACAAABCBBCABBCBBBAACAABBBBACABBBACCCACACCACBBCABBBCBCCAABCAABABCBBBBCAAABCABBBCCACCCCABCBBCCACBCAACBBACAACACCACBAAABCCAACAACACACABBCABBBBBCBBACABBAACBBABBBCCBCACCCCCABAABBCBCCCBBBBBBBBCCBCAABCCBABCCABBAAAACAACAAABBACACBAABBCCABAAABBACBCBBABACBACAAAACCCCCCACCCBBBBBCBBBCBAACBABBBCBCABBCBCBACCCACCCCAAACABBCCBCACABCABCBABCCBBCCBBACACBCAAAAABAACCBBBBACAAABCCACAACCBBBACAABBBAACACBABCCAACAACCBBCCABAAABCACCBACBBBABCCCCACCBAABABABCCBBBAACCCBBCAABCCABACACBBCCBBBCBACCABBCCABCBCCACCACACABCBACBAACABCCBC'

set @input=replace(@input,char(10),'')

insert into dbo.input_text(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)

insert into dbo.input_textmax(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)

insert into dbo.input_int(id,val)
select ordinal,Value FROM string_split(@input,char(13),1)
where TRY_CAST(Value as int) is not null

---

select
	sum(case substring(txt.val, 1 + tally.n, 1) when 'A' then 0 when 'B' then 1 when 'C' then 3 end) result
from dbo.input_text txt
inner join dbo.tally tally
	on tally.n < len(txt.val)