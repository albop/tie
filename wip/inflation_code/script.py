
#%%

import pandas as pd
import pycountry

#%%

# df = pd.read_excel("inflation_code/weo_data.xls")
df = pd.read_csv("weo_data.csv")

df = df.rename(columns={df.columns[0]: "Country"})

def get_iso(x):
    try:
        return pycountry.countries.search_fuzzy(x)[0].alpha_3
    except:
        return ""
df['Country_ISO'] = df['Country'].apply(get_iso)

df = df.melt(id_vars=["Country","Country_ISO"]).rename(columns={'variable': 'Year', 'value': 'Inflation'})

#%%


# keep only countries

df = df[ (df['Country_ISO']!="") & (~df["Inflation"].isna())]


#%%

#
df["Inflation_group"] = pd.qcut(df["Inflation"],5, labels=False)


#%%


#%%


#%%


#%%

import worldmap as wm

year = 2024
year_s = str(year)


ddf = df[df["Year"]==year_s]


#%%

            
import plotly.graph_objects as go
import pandas as pd

fig = go.Figure(
    data=go.Choropleth(
        locations = ddf['Country_ISO'],
        z = ddf["Inflation_group"], # [i for (i,k) in enumerate(countries)],
        # text = df['Country'],
        colorscale = 'Inferno',
        # autocolorscale=False,
        reversescale=True,
        # marker_line_color='darkgray',
        # marker_line_width=0.5,
        colorbar_title = 'Inflation',
    )
)
fig
# %%

fig.update_layout(
    width=1000,
    height=620,
    geo=dict(
        showframe=False,
        showcoastlines=False,
        projection_type='equirectangular'
    ),
)

# %%

