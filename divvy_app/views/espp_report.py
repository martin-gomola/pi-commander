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

def df_to_text_table(df: pd.DataFrame) -> str:
    """
    Convert a DataFrame to a plain text table.
    Adjust the column widths based on the longest item in each column.
    """
    # Create header with column names
    col_widths = {
        col: max(df[col].astype(str).map(len).max(), len(col))
        for col in df.columns
    }
    header_row = "  ".join(f"{col:<{col_widths[col]}}" for col in df.columns)
    separator = "  ".join("─" * col_widths[col] for col in df.columns)
    rows = []
    for _, row in df.iterrows():
        formatted_row = "  ".join(f"{str(row[col]):<{col_widths[col]}}" for col in df.columns)
        rows.append(formatted_row)
    table = f"SUMMARY\n\n{header_row}\n{separator}\n" + "\n".join(rows)
    return table

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

            # Define the stock ticker (e.g., CSCO) for comparison
            ticker = 'CSCO'
            start_date = df['Purchase Date'].min().strftime('%Y-%m-%d')
            end_date = df['Purchase Date'].max().strftime('%Y-%m-%d')

            # Fetch the stock data (CSCO) from yfinance for the purchase dates range
            csco_data = get_stock_data(ticker, start_date, end_date)
            csco_data = csco_data.reset_index().rename(columns={'Date': 'Purchase Date', 'Close': 'CSCO Price'})
            csco_data['Purchase Date'] = csco_data['Purchase Date'].dt.tz_localize(None)

            # Fetch latest CSCO price
            latest_csco_price = yf.Ticker(ticker).history(period='1d')['Close'].iloc[-1]

            # Merge CSCO purchase data with the stock data on 'Purchase Date'
            df = pd.merge(df, csco_data[['Purchase Date', 'CSCO Price']], on='Purchase Date', how='left')

            # Prepare chart data
            chart_data = df[['Purchase Date', 'Purchase Price', 'Offering Date FMV', 'CSCO Price']].dropna()
            chart_data = chart_data.melt(id_vars=['Purchase Date'], var_name='Variable', value_name='Value')

            # Create the line chart using Altair with Datum
            chart = alt.Chart(chart_data).mark_line().encode(
                x=alt.X('Purchase Date:T', title='Date'),
                y=alt.Y('Value:Q', title='Price (USD)'),
                color=alt.Color('Variable:N', legend=alt.Legend(title="Price Type"))
            ).properties(
                title='CSCO Stock Price vs Purchase Price vs Offering Date FMV'
            )

            # Show the chart
            st.altair_chart(chart, use_container_width=True)

            # Calculate total gain and portfolio value
            df['Shares'] = df['Shares Purchased'].astype(float)
            df['Total Cost'] = df['Purchase Price'].astype(float) * df['Shares']
            df['Current Value'] = df['Shares'] * latest_csco_price
            total_cost = df['Total Cost'].sum()
            current_value = df['Current Value'].sum()
            total_gain_usd = current_value - total_cost

            # Assuming a conversion rate (could be dynamically fetched)
            conversion_rate = 0.92  # Example conversion rate USD to EUR
            total_gain_eur = total_gain_usd * conversion_rate

            # Display summary
            summary_df = pd.DataFrame({
                "CSCO Price": [f"{latest_csco_price:,.2f}"],
                "Portfolio Value (EUR)": [f"{current_value * conversion_rate:,.2f}"],
                "Portfolio Value (USD)": [f"{current_value:,.2f}"],
                "Gain (EUR)": [f"{total_gain_eur:,.2f}"],
                "Gain (USD)": [f"{total_gain_usd:,.2f}"],
            })
            st.write("### Portfolio Summary")
            st.code(df_to_text_table(summary_df), language="markdown")
        
        except Exception as e:
            st.error(f"An error occurred: {e}")

if __name__ == "__main__":
    app()
