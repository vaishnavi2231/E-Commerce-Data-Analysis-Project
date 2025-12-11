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

## 📘 Project Overview

This project builds a complete **data engineering and analytics pipeline** using the  
**Brazilian E-Commerce Public Dataset by Olist**.

It includes:

- A **normalized PostgreSQL OLTP database** (3NF)
- A **Python ingestion pipeline** using Pandas + SQLAlchemy
- An **analytics dashboard built with Streamlit**
- Fully automated deployment using **Docker + Docker Compose**

🟢 *The entire system runs with one command:*  
```bash```
docker-compose up --build

## Project Structure

project/
│
├── database/
│   ├── schema.sql               # PostgreSQL table creation
│   ├── security.sql             # RBAC roles & permissions (optional)
│
├── dashboard/
│   ├── app.py                   # Main Streamlit dashboard
│   ├── ingest_data.py           # Python ingestion script
│   ├── Dockerfile               # Builds dashboard container
│   ├── requirement.txt          # Python dependencies
│   ├── data/                    # CSVs used in ingestion
│   └── pages/                   # Multi-page dashboard files
│
├── docker-compose.yml           # Orchestration for database + dashboard
└── README.md                    # Documentation (this file)


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

## How to Run the Entire Project (Docker)

1. Clone the Repository
     git clone <your-repo-url>
     cd project

2. Start Docker Desktop
     Ensure Docker is running on your system.

3. Run Everything with One Command
     docker-compose up --build
   
4. Open the Dashboard
     http://localhost:8501

This will:
1. Start PostgreSQL
2. Execute schema.sql and security.sql
3. Build dashboard container
4. Run ingest_data.py automatically
5. Launch Streamlit dashboard



## 📧 Contributors 

1. Vaishnavi Gawale
MS in Artificial Intelligence, University at Buffalo
Email: vgawale@buffalo.edu

2. Lalasa Mynalli
MS in Artificial Intelligence, University at Buffalo
Email: lalasamy@buffalo.edu
