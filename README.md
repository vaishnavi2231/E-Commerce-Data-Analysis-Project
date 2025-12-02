# E-Commerce-Data-Analysis-Project

The Brazilian E-Commerce Public Dataset by Olist is a real-world dataset from the Olist marketplace in Brazil. It records over 100,000 orders placed between 2016 and 2018, including detailed information about customers, sellers, products, payments, deliveries, and reviews.


The dataset consists of multiple interconnected CSV files — such as orders, customers, sellers, order_items, payments, products, and reviews — enabling end-to-end analysis of the order journey: from purchase and payment to delivery and customer feedback.


## 📂 Dataset

The dataset used for this project is Olist Brazilian E-Commerce Public Dataset.

Due to size restrictions, the raw CSV files are not included in this repository.
You can download the dataset from the following Google Drive link:

👉 **Google Drive Dataset:**  
https://drive.google.com/drive/folders/1KHfSVSZpr5Flyqs3hiq18OID4cTQtS8E?usp=drive_link

Please place the downloaded CSV files into the `data/` folder before running the ingestion script.

## Project Structure

Project/
1. Readme.md
2. docker-compose.yml
3. database/
     - schema.sql
     - security.sql
4. scripts/
     - ingest_data.py
5. data
     - README.md (Google drive link)
6. ER_Diagram.pdf
7. 3NF Justification Report

### Phase 2
8. Phase2_advanced_queries.sql # All advanced analytical queries
9. performance_tuning_report.md # Before/after EXPLAIN ANALYZE results
10. star_schema_report.md # Star schema explanation & grain definitions
11. Phase2_star_schema.drawio.png # Star schema ERD image
12. dbt/ # dbt data warehouse project
