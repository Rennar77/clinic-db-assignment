## 📌 Clinic Booking System – Database Schema
# 📖 Overview

This project is a Clinic Booking System implemented in MySQL.
It demonstrates a complete relational database design with:

Well-structured tables

Proper constraints (PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL)

Relationships (One-to-One, One-to-Many, Many-to-Many)

Sample data for quick testing

The database is designed to handle patients, doctors, specialties, appointments, services, and prescriptions.

# ⚙️ Features of the Schema

Patients with demographics (name, email, gender, DOB, phone)

Doctors with assigned specialties (many-to-many relationship)

Appointments linked to both patients and doctors

Rooms to manage physical consultation locations

Services provided during appointments (many-to-many)

Prescriptions & Notes linked to appointments and patients

Lookup tables for gender and appointment statuses

Constraints included:

Unique patient numbers, doctor staff numbers, and appointment codes

Foreign key references between tables

Simple prevention of exact same-time double bookings for doctors

## 🗂️ File Structure
```
clinic-db-assignment/
│
├─ clinic_schema.sql   # Main SQL script (creates DB + tables + inserts sample data)
└─ README.md           # Documentation

```