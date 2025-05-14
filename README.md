# 👁Biometric Data Acquisition and Recognition

This repository contains the code and data required for biometric data acquisition and recognition. The architecture includes C++ firmware for STM32 Nucleo, MATLAB scripts for processing the acquired data, and detailed reports for each biometric case study.

---

## 🚀 Project Contents

---

### 1. STM32 Nucleo Firmware (C++)
The C++ firmware is designed to acquire biometric data from various sensors using the STM32 Nucleo platform. The sensors and types of data acquisition are as follows:
- Voice Acquisition: Sound acquisition via a microphone.
- ECG Acquisition: Electrocardiographic signal acquisition using an ECG detector.
- Gait Acquisition: Data acquisition related to walking via an accelerometer.
- Potentiometer Test: Oscilloscope test with potentiometer.

Each sensor has a specific datasheet, which can be found in the /DataSheet folder in the repository.

---

### 2. MATLAB Scripts for Data Processing
MATLAB scripts are used to process the data acquired from the sensors. This includes:
- Voice Recognition: For voice acquisition and recognition.
- ECG Processing: For analyzing the acquired ECG signals.
- Gait Data Processing: For extracting information from gait data collected through the accelerometer.

The scripts are written in MATLAB and are well-commented to explain each step of the processing.

---

### 3. Detailed Reports
The reports contain a detailed explanation of each case study, both in terms of the code and the reasoning behind every design choice. Each report includes:
- Theoretical explanations of the acquisition and recognition techniques.
- A description of the steps in the data processing pipeline.
- Analysis of the results obtained and any challenges encountered during implementation.

The reports are available in the /reports folder of the repository.
---
## 📁Repository Structure
```

/BiometricDataAcquisitionAndRecognition
│
├── 📁/Firmware
│    ├── firmware_voice_acquisition.cpp          # Code for voice signal acquisition
│    ├── firmware_gait_acquisition.cpp           # Code for gait data acquisition
│    ├── firmware_potentiometer_test.cpp         # Test code for reading potentiometer
│
├──📁 /DataSheets
│   ├── MAX9814 - Microphone Amplifier with AGC and Low-Noise Microphone Biast.pdf   # Datasheet for MAX9814 mic amp
│   ├── Microfono_electret_CMA-544PF-W.pdf                                         # Datasheet for electret mic
│   ├── nucleo-f091rc.pdf                                                          # STM32 Nucleo board datasheet
│   ├── POTENTIOMETER PTV09A-4225F-B502.pdf                                        # Datasheet for PTV09A potentiometer
│   └── ...                                                                         # Other datasheets
│
├──📁 /Matlab Scripts
│   ├──📁 /ECG Recognition
|   |   └── ecg.m                         # ECG signal processing and recognition
│   ├──📁 /Gait Recognition
|   |   ├── gait_side.m                  # Gait analysis with side sensor placement
|   |   └── gait_top.m                   # Gait analysis with top sensor placement
│   └──📁 /Speaker Recognition
|       └── speaker_recognition.m         # Speaker identification using voice features
│
│
├──📁 /Reports
│   ├── Report _1_Potentiometer.pdf          # Report on potentiometer signal test
│   ├── Report _2_SpeakerRecognition.pdf     # Report on voice-based speaker recognition
│   ├── Report _1_GaitRecognition.pdf        # Report on gait pattern recognition
│   └── Report _1_ECG.pdf                    # Report on ECG signal recognition
├── LICENSE                                # Project license information
└── README.md                              # Overview and instructions for the project

```
---

## ☑️ How to Use

### 1. STM32 Nucleo Firmware
To use the firmware, follow these steps:
1. Clone this repository to your computer.
2. Upload the firmware to your STM32 Nucleo board using your preferred development IDE (e.g., STM32CubeIDE).
3. Follow the instructions in the code to start acquiring biometric data via the specified sensors.

### 2. Data Processing in MATLAB
To process the data, open the MATLAB scripts and load the data acquired via the firmware. Each script contains comments explaining how to perform the operations step by step.

### 3. Reviewing the Reports
The detailed reports are written in pdf format and explain each case study, the underlying code, and the reasoning behind the decisions made during the implementation.

---

## ⚠️ Dependencies

### Firmware
- STM32 Nucleo (hardware)
- MbedOS or equivalent for uploading the firmware

### MATLAB
- MATLAB with the necessary toolboxes for signal processing (e.g., Signal Processing Toolbox)

## Contributing

If you would like to contribute to this project, feel free to fork this repository, create a branch for your changes, and submit a pull request. Any contributions are welcome!

## 🪪 License

This project is distributed under the MIT License

## 👤 Authors
- Raffaele Di Benedetto
- Antonio Nardone
- Anna Vittoria Damato
- Sbiroli Carolina
