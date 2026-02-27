// =========================================================================
// Phase 2.1 Firmware: LM35 Virtual Temperature Sensor Acquisition (For Proteus)
// Purpose: Reads a simulated analog voltage (from the Potentiometer in Proteus) 
// and converts it into a calibrated Celsius temperature. This ensures the
// data is clean before being sent to MATLAB for visualization and logging.
// =========================================================================

// --- 1. DEFINING HARDWARE AND CALIBRATION CONSTANTS ---
// These are constant values that define the physical characteristics of the Arduino and LM35.

#define LM35_PIN A0              // Define the Analog pin where the virtual LM35 sensor (Potentiometer in Proteus) is connected.
                                 // A0 is used for Analog Input.

const float V_REF = 5.0;         // Define the Analog Reference Voltage (VCC). For the standard Arduino UNO, this is 5.0 Volts.
                                 // This is the maximum voltage the Arduino can measure on its analog pins.
                                 
const float ADC_RESOLUTION = 1024.0; // Define the Analog-to-Digital Converter (ADC) resolution. 
                                     // An Arduino's 10-bit ADC has 2^10 = 1024 possible steps, ranging from 0 (0V) to 1023 (5V).
                                     
const float LM35_SENSITIVITY = 0.01; // The LM35 sensor is rated to output 10mV (0.01V) per degree Celsius (°C). 
                                     // This is the key conversion factor required for calibration.

void setup() {
  // Initialize serial communication at 9600 baud rate. 
  // This speed must match the Virtual Terminal in Proteus and the connection settings in MATLAB.
  Serial.begin(9600); 
  
  // CRITICAL STEP: Define the Header for MATLAB Parsing.
  // We print a header row in a Comma-Separated Values (CSV) format. 
  // MATLAB will read this to label the columns when plotting and logging data, 
  // ensuring the final MS Excel file is professional and readable.
  Serial.println("TIME_MS,TEMPERATURE_C"); 
}

void loop() {
  // --- 2. DATA ACQUISITION AND SIGNAL PROCESSING (CALIBRATION) ---

  // Read the raw 10-bit ADC value from the A0 pin.
  // This value will range from 0 (0V) to 1023 (5V), corresponding to the position 
  // of the virtual potentiometer in the Proteus simulation.
  int raw_value = analogRead(LM35_PIN);

  // Convert the Raw ADC Value to Real Voltage (V)
  // This formula scales the raw digital reading back into its equivalent analog voltage:
  // Voltage = (Raw ADC Value / ADC_RESOLUTION) * V_REF
  float voltage_out = (raw_value / ADC_RESOLUTION) * V_REF; 

  // Convert Voltage to Calibrated Temperature (°C)
  // Since the LM35 outputs 0.01V per degree C, dividing the voltage by this sensitivity 
  // factor gives the true temperature:
  // Temperature (°C) = Voltage_out / LM35_SENSITIVITY
  // Example: If Voltage_out = 0.25V, then Temp = 0.25V / 0.01V/°C = 25°C.
  float temp_c = voltage_out / LM35_SENSITIVITY; 

  // --- 3. FORMATTED OUTPUT FOR MATLAB/LOGGING ---
  
  // 1. Send the Time Counter (milliseconds since the Arduino started).
  // The 'millis()' function tracks elapsed time and provides the essential time-series context for data plotting.
  Serial.print(millis());
  
  // Use a comma separator (CSV format) so MATLAB can easily distinguish between the two data columns.
  Serial.print(",");
  
  // 2. Send the Calibrated Temperature (°C).
  // The '2' ensures the output is printed to two decimal places, reflecting professional measurement precision.
  Serial.println(temp_c, 2); 
  
  // Introduce a 1-second (1000 milliseconds) delay between measurements.
  // This sets the final sample rate at 1Hz (one reading per second) and prevents overwhelming the serial buffer.
  delay(1000); 
}
