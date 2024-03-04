#%%

import pandas as pd
import dbnomics

#%%

df_ecb = pd.read_csv(
    "/home/pablo/Teaching/escp/tie/session_inflation/ECB Data Portal_20240304021053.csv"
    ).rename(columns={
        "DATE": "date",
        "HICP - Overall index (ICP.M.U2.N.000000.4.ANR)": "inflation"
    })[['date','inflation']]

df_ecb['zone'] = "Eurozone"
df_ecb['date'] = pd.to_datetime( df_ecb['date'] ).dt.normalize()

#%%

df = dbnomics.fetch_series([
    "IMF/CPI/Q.FR.PCPI_PC_CP_A_PT",
    "IMF/CPI/Q.GB.PCPI_PC_CP_A_PT",
    "IMF/CPI/Q.US.PCPI_PC_CP_A_PT",
]
)
df['date'] = df['period'].dt.normalize()

df_row = df[['date','value',"Reference Area"]].rename(
    columns={'value':'inflation', "Reference Area": "zone"})

#%%

df = pd.concat([df_ecb, df_row])

#%%

import altair as alt
from altair import datum
import datetime

ddf = df[df['date']>="1995-01-01"]
ch = alt.Chart(ddf).mark_line().encode(
    x="date",
    y="inflation",
    color="zone"
).properties(
    width=400,
    height=250
)

ch.save("inflation_short_horizon.png", ppi=600)
ch

#%%
import altair as alt
from altair import datum
import datetime


ch = alt.Chart(df).mark_line().encode(
    x="date",
    y="inflation",
    color="zone"
).properties(
    width=400,
    height=250
)

ch.save("inflation_long_horizon.png", ppi=600)
ch
