import streamlit as st
import pandas as pd
import altair as alt
import yfinance as yf

def clean_dollar_value(value):
    try:
        value = str(value).replace("$", "").replace(",", "").strip()
        return float(value) if value else None
    except (ValueError, TypeError):
        return None

def get_stock_data(ticker, start_date, end_date):
    """
    Fetch stock data from yfinance for the given ticker between the start and end dates.
    """
    stock = yf.Ticker(ticker)
    data = stock.history(start=start_date, end=end_date)
    return data[['Close']]

def app():
    st.title("CSCO Tax Report")

    uploaded_file = st.file_uploader("Upload My_ESPP_Purchases.xlsx", type=["xlsx"])

    if uploaded_file:
        try:
            # Read the uploaded file
            df = pd.read_excel(uploaded_file, engine="openpyxl", skiprows=5)
            df.columns = df.iloc[0]
            df = df[1:].reset_index(drop=True)

            # Clean up the data
            unwanted_texts = [
                "Date as of:", "Please note:", "All amount fields are in US Dollars.",
                "Cisco provides the information", "In addition, the information",
                "Please notify People Support Services"
            ]
            df = df[~df.apply(lambda row: row.astype(str).str.contains('|'.join(unwanted_texts), case=False, na=False)).any(axis=1)]
            df = df[~df.iloc[:, 0].str.startswith('Total', na=False)]
            df = df.dropna(subset=['Purchase Date'])

            # Show processed data
            st.write("### Processed Data")
            st.dataframe(df)

            # Convert 'Purchase Date' to datetime (ensure no timezone)
            df['Purchase Date'] = pd.to_datetime(df['Purchase Date'], errors='coerce').dt.tz_localize(None)

            # Define the stock ticker (e.g., SXRV) for comparison
            ticker = 'NCLH'  # Use the correct ticker for the ETF
            start_date = df['Purchase Date'].min().strftime('%Y-%m-%d')  # Get the earliest purchase date
            end_date = df['Purchase Date'].max().strftime('%Y-%m-%d')    # Get the latest purchase date

            # Fetch the stock data (SXRV) from yfinance for the purchase dates range
            sxrv_data = get_stock_data(ticker, start_date, end_date)
            sxrv_data = sxrv_data.reset_index().rename(columns={'Date': 'Purchase Date', 'Close': 'SXRV Price'})

            # Ensure no timezone for the 'Purchase Date' in sxrv_data as well
            sxrv_data['Purchase Date'] = sxrv_data['Purchase Date'].dt.tz_localize(None)

            # Merge CSCO purchase data with the SXRV stock data on 'Purchase Date'
            df = pd.merge(df, sxrv_data[['Purchase Date', 'SXRV Price']], on='Purchase Date', how='left')

            # Prepare chart data
            chart_data = df[['Purchase Date', 'Purchase Price', 'Offering Date FMV', 'SXRV Price']].dropna()

            # Create the line chart using Altair
            chart = alt.Chart(chart_data).transform_fold(
                ['Purchase Price', 'Offering Date FMV', 'SXRV Price'],
                as_=['Variable', 'Value']
            ).mark_line().encode(
                x='Purchase Date:T',
                y='Value:Q',
                color='Variable:N'
            ).properties(
                title='CSCO Stock Price vs Purchase Price vs SXRV Price'
            )

            # Show the chart
            st.altair_chart(chart, use_container_width=True)

        except Exception as e:
            st.error(f"An error occurred: {e}")

if __name__ == "__main__":
    app()
