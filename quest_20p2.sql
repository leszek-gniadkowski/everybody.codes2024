set nocount on

drop table if exists tally
go
create table tally(n int)
create clustered index itally on dbo.tally(n)
insert into tally(n)
select value from generate_series(0,100000,1)
go

drop table if exists input_text
create table input_text(id int,val varchar(max))
go

drop table if exists grid
create table grid(counter int, last_step int, x int, y int, x_prev int, y_prev int, checkpoint_layer int, alt int)
go

drop table if exists mapping
create table mapping(x_src int, y_src int, x_dest int, y_dest int, alt_delta int, checkpoint_dest int)
create clustered index imapping on mapping(x_src, y_src, x_dest, y_dest)
go

-- 10m

declare @input varchar(max)

set @input='####S####
#-.+++.-#
#.+.+.+.#
#-.+.+.-#
#A+.-.+C#
#.+-.-+.#
#.+.B.+.#
#########'

set @input=replace(@input, char(10), '')

insert into input_text(id, val)
select ordinal, Value from string_split(@input, char(13), 1)

insert into mapping(x_src, y_src, x_dest, y_dest, alt_delta, checkpoint_dest)
select
	 g1.x x_from
	,g1.y y_from
	,g2.x x_to
	,g2.y y_to
	,case point
		when '-' then -2
		when '+' then 1
		else -1
		end alt_delta
	,case point
		when 'A' then 1
		when 'B' then 2
		when 'C' then 3
		when 'S' then 4
		end	checkpoint_dest
from
(
	select 
		t.n + 1 x
		,x.id y
	from dbo.input_text x
	inner join tally t
		on t.n < len(x.val)
	where substring(x.val, 1 + t.n, 1) <> '#'
) g1
inner join 
(
	select 
		t.n + 1 x
		,x.id y
		,substring(x.val, 1 + t.n, 1) point
	from dbo.input_text x
	inner join tally t
		on t.n < len(x.val)
	where substring(x.val, 1 + t.n, 1) <> '#'
) g2
	on (	(g2.x = g1.x + 1	and g2.y = g1.y		)
		or	(g2.x = g1.x - 1	and g2.y = g1.y		)
		or	(g2.x = g1.x		and g2.y = g1.y + 1	)
		or	(g2.x = g1.x		and g2.y = g1.y - 1	)
		)

insert into grid(counter, last_step, x, y, x_prev, y_prev, checkpoint_layer, alt)
select
	0 counter
	,0 last_step
	,s.x
	,s.y
	,-1 prev_x
	,-1 prev_y
	,0 chekcpoint_layer
	,0 alt
from 
(
	select 
		t.n + 1 x
		,x.id y
	from dbo.input_text x
	inner join tally t
		on t.n < len(x.val)
	where substring(x.val, 1 + t.n, 1) = 'S'
) s

declare @counter int
set @counter = 0

while not exists (select null from grid where checkpoint_layer = 4 and alt >= 0)
begin

	;with movements as
	(
	select
		m.x_dest	
		,m.y_dest
		,m.x_src
		,m.y_src
		,iif(g.checkpoint_layer + 1 = m.checkpoint_dest
				,m.checkpoint_dest
				,g.checkpoint_layer) checkpoint_layer
		,g.alt + m.alt_delta alt_dest
	from grid g
	inner join mapping m
		on m.x_src = g.x and m.y_src = g.y
			and not (m.x_dest = g.x_prev and m.y_dest = g.y_prev )
	where g.last_step = @counter
	)
	,incoming as
	(
	select
		m.x_dest
		,m.y_dest
		,m.x_src
		,m.y_src
		,m.checkpoint_layer
		,max(m.alt_dest) alt_desc
	from movements m
	group by m.x_src, m.y_src, m.x_dest, m.y_dest, m.checkpoint_layer
	)
	
	insert into grid(counter, last_step, x, y, x_prev, y_prev, checkpoint_layer, alt)
	select
		@counter + 1 counter
		,iif(i.x_src is null, g.last_step, @counter + 1) last_step
		,isnull(i.x_dest, g.x) x
		,isnull(i.y_dest, g.y) y
		,isnull(i.x_src, g.x_prev) x_prev
		,isnull(i.y_src, g.y_prev) y_prev
		,isnull(i.checkpoint_layer, g.checkpoint_layer) checkpoint_layer
		,isnull(i.alt_desc,g.alt) alt_desc
	from incoming i
	full join grid g
		on  i.x_src = g.x_prev and i.y_src = g.y_prev
			and i.x_dest = g.x and i.y_dest = g.y
			and i.checkpoint_layer = g.checkpoint_layer
	
	delete from grid where counter = @counter
	
	print '-- STEP -- ' + cast(@counter as varchar(100))
	
	set @counter = @counter + 1

end

select max(counter) shortest_time from grid
