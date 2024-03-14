import pandas as pd
from sqlalchemy import create_engine

conn_string = 'postgresql://postgres:admin@localhost/esport'
db = create_engine(conn_string)
conn = db.connect()

files=['GeneralEsportDataclean','HistoricalEsportData']
for file in files:

 df = pd.read_csv(f"C:\\Users\\matas\\Downloads\\esport\\{file}.csv")
 df.to_sql(file, con=conn, if_exists='replace', index=False)


