DECLARE
  TYPE transac_table IS TABLE OF Transactions%ROWTYPE;
  transac_temp transac_table;
  v_Supplier_name Masterdata.supplier_name%TYPE := null;
  v_Product_name Masterdata.product_name%TYPE := null;
  v_Supplier_id Masterdata.product_name%TYPE := null;
  v_Price Masterdata.price%TYPE :=0;
  v_Date number := 0;
  v_YEAR number := 0;
  v_QUARTER number := 0;
  v_MONTH number := 0;
  V_WEEK number := 0;
  v_DAY varchar2(10) := '0';
  
  CURSOR transac_cursor IS
    SELECT * FROM Transactions;
BEGIN
  OPEN transac_cursor;
  LOOP
    FETCH transac_cursor
    BULK COLLECT INTO transac_temp LIMIT 50;
    EXIT WHEN transac_cursor%notfound;

      FOR i IN transac_temp.FIRST .. transac_temp.LAST LOOP

        SELECT supplier_name, product_name, supplier_id, price 
        INTO v_Supplier_name, v_Product_name, v_Supplier_id, v_Price 
        FROM Masterdata 
        WHERE product_id = transac_temp(i).product_id;

        BEGIN     
          INSERT INTO Customer_D VALUES (transac_temp(i).customer_id, transac_temp(i).customer_name);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN null;
        END;

        BEGIN
          INSERT INTO Store_D VALUES (transac_temp(i).store_id, transac_temp(i).store_name);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN null;
        END;

        BEGIN
          INSERT INTO Supplier_D VALUES (v_Supplier_id, v_Supplier_name);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN null;
        END;

        BEGIN
          INSERT INTO Product_D VALUES (transac_temp(i).product_id, v_Product_name, v_Price);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN null;
        END;

        BEGIN
          v_DATE := TO_CHAR(transac_temp(i).t_date,'ddd');
          v_DAY := TO_CHAR(transac_temp(i).t_date,'day');
          v_YEAR := TO_CHAR(transac_temp(i).t_date,'YYYY');
          v_QUARTER := TO_CHAR(transac_temp(i).t_date,'Q');
          v_MONTH := TO_CHAR(transac_temp(i).t_date,'MM');
          v_WEEK := TO_CHAR(transac_temp(i).t_date,'WW');

          INSERT INTO Time_d (TIME_ID, DATE_YEAR_CODE, DAY_CODE, WEEK_CODE, MONTH_CODE, QUARTER_CODE, YEAR_CODE)
          VALUES (transac_temp(i).t_date, v_DATE, v_DAY, v_WEEK, v_MONTH, v_QUARTER, v_YEAR);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN null;
        END;

        INSERT INTO Sales_Fact 
        VALUES (transac_temp(i).store_id, v_Supplier_id, transac_temp(i).product_id, transac_temp(i).customer_id,
          transac_temp(i).T_DATE, transac_temp(i).quantity, v_Price * transac_temp(i).quantity);

      END LOOP;

    END LOOP;
  CLOSE transac_cursor;
  COMMIT;
END;
