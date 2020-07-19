--Parametro moneda - Lista de valores:
select    FCVL.DESCRIPTION,
          FCVL.CURRENCY_CODE
from      FND_CURRENCIES_VL  		FCVL
order by  FCVL.DESCRIPTION asc