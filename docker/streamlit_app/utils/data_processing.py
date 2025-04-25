# streamlit_app/utils/data_processing.py

import pandas as pd

def process_dividends(df: pd.DataFrame, conversion_rate: float, countries: list) -> pd.DataFrame:
    # Convert USD dividends to EUR where applicable
    df["Dividends (EUR)"] = df.apply(
        lambda row: row["Dividends"] / conversion_rate if row["Currency"] == "USD" else row["Dividends"],
        axis=1
    )
    df["After Tax (EUR)"] = df.apply(
        lambda row: row["Dividends (EUR)"] * (1 - row["Tax %"] / 100),
        axis=1
    )
    
    # Create summary by country
    summary = df.groupby("Country").agg({
        "Dividends (EUR)": "sum",
        "After Tax (EUR)": "sum"
    }).reset_index()

    # Add USD dividend summary where applicable
    for index, row in summary.iterrows():
        country = row['Country']
        country_data = next((item for item in countries if item[1] == country), None)
        if country_data and country_data[3] == "USD":
            usd_dividends = df[(df["Country"] == country) & (df["Currency"] == "USD")]["Dividends"].sum()
            summary.at[index, "Dividends (USD)"] = usd_dividends
        else:
            summary.at[index, "Dividends (USD)"] = 0  
    return summary
