# **CogniAnchor**

### **AI Aid for Alzheimer’s & Dementia Patients**

CogniAnchor is an **AI-powered mobile application** designed to assist Alzheimer’s and dementia patients in daily living while enabling caretakers to monitor safety, manage reminders, and respond to emergencies in real time.

---

## **Key Features**

### **AI Voice Agent**

* Voice-based interaction for patients
* Speech-to-Text and Text-to-Speech for seamless communication
* Provides emotional reassurance during confusion

### **Smart Reminders**

* Caretakers can create and manage reminders
* Patients receive **audio alerts** for medications and daily routines
* Reminder synchronization between patient and caretaker

### **Face Recognition**

* Scan faces using the mobile camera
* Detects faces on-device and matches with stored profiles
* Announces identity to help patients recognize people

### **Real-Time Location & Safety**

* Live location tracking during emergencies
* Safe-zone (geofencing) exit alerts
* Emergency microphone sharing

---

## **User Roles**

### **Patient**

* Receives reminders
* Uses AI voice interaction
* Scans faces for identification
* Triggers safety alerts

### **Caretaker**

* Manages patient profiles
* Uploads known faces
* Sets reminders
* Monitors live location
* Receives emergency alerts

---

## **Tech Stack**

### **Frontend**

* **Flutter**

### **Backend**

* **FastAPI (Python)**

### **Database**

* **PostgreSQL**

### **AI & ML**

* OpenAI Whisper (Speech-to-Text)
* pyttsx3 (Text-to-Speech)
* Google ML Kit (Face Detection)
* MobileFaceNet (TFLite)

### **Other Services**

* Firebase (Notifications)
* WebSockets (Real-time communication)

---

## **System Architecture**

```
Flutter Mobile App
        ↓
FastAPI Backend
        ↓
PostgreSQL Database
```

AI services are integrated for **voice interaction**, **face recognition**, and **real-time monitoring**.

---

## 🔁 **Sequence Diagrams**

### 🧑‍⚕️ **Caretaker Interaction Flow**

This diagram illustrates caretaker activities such as patient registration, face uploads, reminder management, live location monitoring, and emergency communication.

![Caretaker Sequence Diagram](docs/images/caretaker-sequence-diagram.png)

---

### 🧓 **Patient Interaction Flow**

This diagram shows how a patient receives reminders, interacts with the AI agent, uses face recognition, and triggers safety alerts.

![Patient Sequence Diagram](docs/images/patient-sequence-diagram.png)

---
