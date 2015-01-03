Prompt INSERTING into DATA_DRIVEN_TEST
SET DEFINE OFF;



Insert into DATA_DRIVEN_TEST (ID) values ('1');
Insert into DATA_DRIVEN_TEST (ID) 
 select max(d.id)+1 from DATA_DRIVEN_TEST d;
Insert into DATA_DRIVEN_TEST (ID) 
 select max(d.id)+1 from DATA_DRIVEN_TEST d;
 
Insert into data_driven_test(id)
 select d.id+rownum from DATA_DRIVEN_TEST d, DATA_DRIVEN_TEST d2, DATA_DRIVEN_TEST d3
  where d.id >=(select max(id) from data_driven_test)
  and rownum <=100;
  
Insert into data_driven_test(id)
 select d.id+rownum from DATA_DRIVEN_TEST d, DATA_DRIVEN_TEST d2, DATA_DRIVEN_TEST d3
  where d.id >=(select max(id) from data_driven_test)
  and rownum <=100;
Commit;

