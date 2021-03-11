CALL proc_drop_index("mysql_learning","dept");
select count(1) from dept;
select count(1) from emp;

show index from emp;
CALL proc_drop_index("mysql_learning","emp");

-- 创建索引 单个索引和复合索引
EXPLAIN select SQL_NO_CACHE * from emp where age=30; -- 0.161  索引0.058
create INDEX idx_age on emp(age); 

EXPLAIN select SQL_NO_CACHE * from emp where age=30 and deptid=4000; -- 0.128  索引0.002
create INDEX idx_age_deptid on emp(age,deptid);

EXPLAIN select SQL_NO_CACHE * from emp where age=30 and deptid=4 and `name` = 'abcd'; -- 0.139 索引 0.002
EXPLAIN select SQL_NO_CACHE * from emp where  deptid=4 and age=30 and `name` = 'abcd';  -- 调整顺序索引不会失效，因为优化器会优化查询顺序
create INDEX idx_age_deptid_name on emp(age,deptid,name);

-- 复合索引失效 符合索引按照索引顺序分层，所以查询时必须按顺序存在对应列
EXPLAIN select SQL_NO_CACHE * from emp where  deptid=4 and `name` = 'abcd';  -- 全表扫描 因为没有第一层 无法获取下层索引
EXPLAIN select SQL_NO_CACHE * from emp where age=30 and deptid=4 ;    -- 命中2个索引
EXPLAIN select SQL_NO_CACHE * from emp where age=30 and `name` = 'abcd';  -- 命中一个索引
EXPLAIN select SQL_NO_CACHE * from emp where age>30 and  deptid=4 and `name` = 'abcd'; -- 全表扫描 因为范围查询会打断复合索引向下传递
-- 命中2个索引 （优化方案：尽量让范围查询字段建在索引的最后一个列，例如常用字段金额/时间等）
EXPLAIN select SQL_NO_CACHE * from emp where age=30  and `name` = 'abcd' and  deptid>4; -- 重建索引后 命中3个索引
show index from emp;
CALL proc_drop_index("mysql_learning","emp");
create INDEX idx_age_deptid_name on emp(age,name,deptid);

-- 索引失效
EXPLAIN select SQL_NO_CACHE * from emp where age=30  and `name` like 'abcd%' and  deptid=4; -- 百分号不在第一个位置 索引未失效，且不影响传递 命中3个
EXPLAIN select SQL_NO_CACHE * from emp where age=30  and `name` like '%abcd%' and  deptid=4; -- 只命中1个索引 打断了传递

-- 不等于 索引失效
EXPLAIN select SQL_NO_CACHE * from emp where  `name` <> 'abc'; -- 0.546 
create INDEX idx_name on emp(name); -- 还是全表扫
EXPLAIN select SQL_NO_CACHE * from emp where  `name` = 'abc' or `name` = 'abcd'; -- 命中索引
EXPLAIN select SQL_NO_CACHE * from emp where  `name` < 'abc'; -- 命中索引
EXPLAIN select SQL_NO_CACHE * from emp where  `name` < 'abc' or `name` > 'abc'; -- 改成范围还是索引失效 因为索引的效率没有全表扫描快，所以mysql选择全表扫描
EXPLAIN select SQL_NO_CACHE max(deptid),min(deptid) from emp;
EXPLAIN select SQL_NO_CACHE * from emp where deptid<2 or deptid>9208; -- 查询出来结果数量比较少会走索引
create INDEX idx_deptid on emp(deptid); 

-- 数据类型错误 索引失效
create INDEX idx_name on emp(name);
EXPLAIN select SQL_NO_CACHE * from emp where  `name` = 123; -- 全表扫描 这里会做类型转换
EXPLAIN select SQL_NO_CACHE * from emp where  `name` = '123'; -- 命中索引

CALL proc_drop_index("mysql_learning","emp");
-- is not 索引失效
create INDEX idx_name on emp(name);
EXPLAIN select SQL_NO_CACHE * from emp where  `name` is null; -- 命中索引
EXPLAIN select SQL_NO_CACHE * from emp where  `name` is not null; -- 索引失效

-- not exists 索引不会失效
EXPLAIN select SQL_NO_CACHE * from emp where  EXISTS (select 1 from emp e where e.deptid = emp.age); -- emp表全表扫描  e表走索引
create INDEX idx_deptid on emp(deptid);
create INDEX idx_age on emp(age);

-- 当emp表数据量大时 exists性能极低，如果数据量小 性能稳定
EXPLAIN select SQL_NO_CACHE * from emp where not EXISTS (select 1 from emp e where e.deptid = emp.age); -- emp表全表扫描  e表走索引

-- 列名进行函数处理 失效
EXPLAIN select SQL_NO_CACHE * from emp where  LEFT(`name`,3) = 'abc';  -- 全表扫描
EXPLAIN select SQL_NO_CACHE * from emp where  `name` = CONCAT('abc','d');  -- 命中索引