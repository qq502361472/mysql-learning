drop TABLE if EXISTS dept;
create table `dept`(
`id` INT(11) not null auto_increment,
`deptName` VARCHAR(30) default null,
`address` VARCHAR(40) default null,
ceo int null,
PRIMARY key (`id`)
)ENGINE = INNODB AUTO_INCREMENT = 1 DEFAULT CHARSET = utf8;

CREATE TABLE `emp` (
	`id` INT (11) NOT NULL auto_increment,
	`name` VARCHAR (30) DEFAULT NULL,
	`age` INT (3) DEFAULT NULL,
	`deptId` INT (11) DEFAULT NULL,
	`empno` INT NOT NULL,
	PRIMARY KEY (`id`)
#CONSTRAINT `fk_dept_id` FOREIGN KEY (`deptId`) REFERENCES `t_dept` (`id`)
) ENGINE = INNODB AUTO_INCREMENT = 1 DEFAULT CHARSET = utf8;


select @@log_bin_trust_function_creators from dual;
-- 开启函数编程 mysql默认关闭，避免主从复制时调用函数后 主从结果不同，比如时间
set global log_bin_trust_function_creators=1;

-- 封装随机字符串函数
DELIMITER $$
CREATE FUNCTION random_string (n INT) RETURNS VARCHAR (255)
BEGIN
DECLARE chars_str VARCHAR (100) DEFAULT 'abcdefghijklmnopqrstuvwxyzABCDEFJHIJKLMNOPQRSTUVWXYZ' ;
DECLARE return_str VARCHAR (255) DEFAULT '' ;
DECLARE i INT DEFAULT 0 ;
WHILE i < n DO
SET return_str = CONCAT(
	return_str,
	SUBSTRING(
		chars_str,
		FLOOR(1 + RAND() * 52),
		1
	)
) ;
SET i = i + 1 ;
END
WHILE ; RETURN return_str ;
END$$

-- 封装随机数字函数
DELIMITER $$
CREATE FUNCTION random_num (from_num INT,to_num INT) RETURNS INT(11)
BEGIN
DECLARE i INT DEFAULT 0 ;
SET i = FLOOR(from_num+RAND()*(to_num-from_num+1)) ;
RETURN i ;
END$$

-- 删除 函数
drop function random_string;
drop function random_num;

-- 创建存储过程 插入员工表数据
drop PROCEDURE if EXISTS insert_emp;
DELIMITER $$
CREATE PROCEDURE insert_emp (START INT, max_num INT)
BEGIN
DECLARE i INT DEFAULT 0 ;
SET autocommit = 0 ; # 修改为手动提交
REPEAT
SET i = i + 1 ; INSERT INTO emp (empno, `name`, age, deptid)
VALUES
	(
		(START + i),
		random_string (6),
		random_num (30, 50),
		random_num (1, 10000)
	) ; UNTIL i = max_num
END
REPEAT; COMMIT ; END$$

-- 创建存储过程 插入部门表数据
drop PROCEDURE if EXISTS insert_dept;
DELIMITER $$
CREATE PROCEDURE insert_dept (max_num INT)
BEGIN
DECLARE i INT DEFAULT 0 ;
SET autocommit = 0 ; # 修改为手动提交
REPEAT
SET i = i + 1 ; INSERT INTO dept (deptname, address, ceo)
VALUES
	(
		random_string (8),
		random_string (10),
		random_num (1, 500000)
	) ; UNTIL i = max_num
END
REPEAT; COMMIT ; END$$

-- 调用存储过程
DELIMITER ;
CALL insert_dept(10000);

DELIMITER ;
CALL insert_emp(10000,500000);

-- 执行特别慢   172s  修改虚拟机内存为1G 修改一下服务端参数在 docker.cnf文件
innodb_log_file_size = 1024M
innodb_log_buffer_size = 256M 
innodb_flush_log_at_trx_commit = 0
innodb_buffer_pool_size = 4G
innodb_buffer_pool_instances = 4 
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_io_capacity = 500
select @@innodb_log_file_size/1024/1024 from dual;

-- 需要开发一个删除索引的存储过程
-- 查看索引
show index from t_emp;

-- 索引存储表 information_schema.statistics
SELECT
	t.index_name
FROM
	information_schema.statistics t
WHERE
	t.table_name = 't_emp'
AND t.index_schema = 'mysql_learning'  -- 数据库名
AND t.index_name <> 'PRIMARY' -- 主键索引不可删除
AND t.seq_in_index = 1; -- 符合索引的索引名称相同，但是有多行数据，只需匹配一个索引名称即可 取下标为1的那条

-- 删除索引存储过程
drop PROCEDURE if EXISTS proc_drop_index;
DELIMITER $$
CREATE PROCEDURE `proc_drop_index` (
	dbname VARCHAR (200),
	tablename VARCHAR (200)
)
BEGIN
DECLARE done INT DEFAULT 0 ;
DECLARE _index VARCHAR (200) DEFAULT '' ;
DECLARE _cur CURSOR FOR SELECT
	index_name
FROM
	information_schema.statistics
WHERE
	table_name = tablename
AND index_schema = dbname
AND index_name <> 'PRIMARY'
AND seq_in_index = 1 ;
DECLARE CONTINUE HANDLER FOR NOT FOUND
SET done = 2 ; OPEN _cur ; FETCH _cur INTO _index ;
WHILE _index <> '' DO
SET @str = CONCAT(
	"drop index ",
	_index,
	" on ",
	tablename
) ; PREPARE sql_str
FROM
	@str ; EXECUTE sql_str ; DEALLOCATE PREPARE sql_str ;
SET _index = '' ; FETCH _cur INTO _index ;
END
WHILE ; CLOSE _cur ; END $$
