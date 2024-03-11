#%%

import pandas as pd


df = pd.read_csv("API_FR.INR.LEND_DS2_en_csv_v2_2790.csv",skiprows=4)

#%%

import worldmap as wm


for year_i in range(2000, 2023):

    year = str(year_i)
    filename = f"lending_rates/lending_rate_{year}.svg"

    valid = ~df[year].isna()
    countries = list(df[valid]['Country Code'])

    opacity = (df[valid][year])
    min_val = min(opacity)
    max_val = max(opacity)
    opacity = (opacity-min_val)/(max_val-min_val)
    opacity = list(opacity)
    results = wm.plot(countries, opacity=opacity, map_name='world', cmap='Blues', showfig=False, filename=filename)




