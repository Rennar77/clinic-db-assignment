-- clinic_schema.sql
-- Clinic Booking System schema (MySQL )


-- 1. Create database
CREATE DATABASE IF NOT EXISTS clinic_db
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clinic_db;

-- 2. Lookup tables
CREATE TABLE genders (
  gender_id TINYINT UNSIGNED PRIMARY KEY,
  name VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;
INSERT IGNORE INTO genders (gender_id, name) VALUES
(1, 'Male'), (2, 'Female'), (3, 'Other');

CREATE TABLE appointment_statuses (
  status_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;
INSERT IGNORE INTO appointment_statuses (name) VALUES
('Scheduled'), ('Completed'), ('Cancelled'), ('No-Show');

CREATE TABLE specialties (
  specialty_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;
INSERT IGNORE INTO specialties (name) VALUES
('General Practice'), ('Pediatrics'), ('Cardiology'), ('Dermatology');

-- 3. Core tables: patients, doctors
CREATE TABLE patients (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_number VARCHAR(20) NOT NULL UNIQUE, 
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(30),
  dob DATE,
  gender_id TINYINT UNSIGNED,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_patients_gender FOREIGN KEY (gender_id) REFERENCES genders(gender_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE doctors (
  doctor_id INT AUTO_INCREMENT PRIMARY KEY,
  staff_number VARCHAR(20) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(30),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 4. Many-to-many: doctors <-> specialties
CREATE TABLE doctor_specialties (
  doctor_id INT NOT NULL,
  specialty_id INT NOT NULL,
  PRIMARY KEY (doctor_id, specialty_id),
  CONSTRAINT fk_ds_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ds_specialty FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 5. Rooms (optional resource)
CREATE TABLE rooms (
  room_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  location VARCHAR(100)
) ENGINE=InnoDB;

-- 6. Appointments
-- We store start and end datetime for more flexible scheduling.
-- We add a UNIQUE index on (doctor_id, appointment_start) to prevent exactly identical start-times for same doctor.
-- NOTE: preventing overlapping times fully requires application logic or triggers 
CREATE TABLE appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_code VARCHAR(25) NOT NULL UNIQUE,
  doctor_id INT NOT NULL,
  room_id INT,
  appointment_start DATETIME NOT NULL,
  appointment_end DATETIME NOT NULL,
  status_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  reason VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_appt_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_appt_room FOREIGN KEY (room_id) REFERENCES rooms(room_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_appt_status FOREIGN KEY (status_id) REFERENCES appointment_statuses(status_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CHECK (appointment_end > appointment_start)
) ENGINE=InnoDB;

-- Prevent two appointments from having exactly the same start for a single doctor (simple constraint)
CREATE UNIQUE INDEX ux_appointments_doctor_start ON appointments (doctor_id, appointment_start);

-- 7. Many-to-many example: appointment <<->>> services 
CREATE TABLE services (
  service_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255),
  price DECIMAL(10,2) DEFAULT 0.00
) ENGINE=InnoDB;

CREATE TABLE appointment_services (
  appointment_id INT NOT NULL,
  service_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  PRIMARY KEY (appointment_id, service_id),
  CONSTRAINT fk_as_appt FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_as_service FOREIGN KEY (service_id) REFERENCES services(service_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 8. Audit / notes: prescriptions & notes
CREATE TABLE notes (
  note_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  author_doctor_id INT,
  note_text TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_note_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_note_doctor FOREIGN KEY (author_doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE prescriptions (
  prescription_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL,
  medication VARCHAR(255) NOT NULL,
  dosage VARCHAR(100),
  instructions TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_presc_appt FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 9. Sample data 
INSERT INTO patients (patient_number, first_name, last_name, email, phone, dob, gender_id)
VALUES
('CLINIC-0001','Alice','Muthoni','alice@example.com','+254700111222','1990-04-12',2),
('CLINIC-0002','Kamau','Otieno','kamau@example.com','+254700333444','1982-11-30',1);

INSERT INTO doctors (staff_number, first_name, last_name, email, phone)
VALUES
('DOC-001','James','Onyango','james.onyango@clinic.local','+254700555666'),
('DOC-002','Grace','Akinyi','grace.akinyi@clinic.local','+254700777888');

INSERT INTO doctor_specialties (doctor_id, specialty_id) VALUES
(1, 1), (1, 3), (2, 1), (2, 2);

INSERT INTO rooms (name, location) VALUES
('Consult Room 1','Ground Floor'), ('Consult Room 2','Ground Floor');

INSERT INTO appointment_statuses (name) VALUES ('Rescheduled'); -- additional status

-- Insert an appointment sample
INSERT INTO appointments (appointment_code, patient_id, doctor_id, room_id, appointment_start, appointment_end, status_id, reason)
VALUES
('APPT-20250919-0001', 1, 1, 1, '2025-09-25 09:00:00', '2025-09-25 09:20:00', 1, 'Routine checkup');

INSERT INTO services (name, description, price) VALUES
('Consultation','Doctor consultation (20min)', 10.00),
('ECG','Electrocardiogram', 25.00);

INSERT INTO appointment_services (appointment_id, service_id, quantity) VALUES
(1, 1, 1);

-- 10. Useful helper views (optional)
CREATE OR REPLACE VIEW vw_doctor_schedule AS
SELECT d.doctor_id, CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
       a.appointment_id, a.appointment_code, a.appointment_start, a.appointment_end, p.patient_id,
       CONCAT(p.first_name, ' ', p.last_name) AS patient_name, s.name AS status
FROM doctors d
LEFT JOIN appointments a ON a.doctor_id = d.doctor_id
LEFT JOIN patients p ON a.patient_id = p.patient_id
LEFT JOIN appointment_statuses s ON a.status_id = s.status_id;


