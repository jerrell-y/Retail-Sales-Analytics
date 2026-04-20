import psycopg2
from sqlalchemy import create_engine
import pandas as pd

df = pd.read_csv("train.csv")

# Step 1: Rename columns
df.columns = (
    df.columns
    .str.strip()
    .str.lower()
    .str.replace(' ', '_')
    .str.replace('-', '_')
)

# Step 2: Convert dates BEFORE inserting
df['order_date'] = pd.to_datetime(df['order_date'], dayfirst=True)
df['ship_date']  = pd.to_datetime(df['ship_date'],  dayfirst=True)

# Step 3: Verify — should show YYYY-MM-DD format, NOT DD/MM/YYYY
print(df[['order_date', 'ship_date']].head(3))
print(df.dtypes)

# Step 4: Insert
engine = create_engine("postgresql://postgres:Snowball!1124@localhost:5432/retail_db")

df.to_sql(
    name="superstore",
    con=engine,
    if_exists="append",
    index=False
)

print("Done! Data inserted.")