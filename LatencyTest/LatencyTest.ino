/**
 * @file LatencyTest.ino
 * @author Leonardo Molina (leonardomt@gmail.com).
 * @date 2019-04-15
 * @version 1.1.190414
 * 
 * @brief Test latencies introduced by USB/UART communication with a computer and feedback an RC wave.
**/


const uint32_t nSync = 100;
const uint32_t baudrate = 115200;
const uint32_t totalDuration = 2000;
const uint32_t chargeDuration = 100;
const uint8_t chargePin = 13;
const uint8_t feedbackPin = A0;

const uint8_t zero = 0;

bool start = false;
void setup() {
	pinMode(chargePin, OUTPUT);
	digitalWrite(chargePin, LOW);
	delay(100);
	Serial.begin(baudrate);
	// Sync.
	for (int i = 0; i < nSync; i++)
		Serial.write(zero);
}

void loop() {
	while (Serial.available() > 0) {
		uint8_t input = Serial.read();
		// All numbers are echoed.
		Serial.write(input);
		// 0 encondes beginning of a pulse. Ignore duplicated pulses.
		start = input == 0;
	}
	
	if (start) {
		start = false;
		// Rising phase: Charge then discharge capacitor.
		forward();
		uint32_t elapsed = charge(chargeDuration);
		// Falling phase (continuation).
		discharge(totalDuration - elapsed);
		// 0 encodes end of wave.
		Serial.write(zero);
		Serial.write(zero);
	}
}

uint32_t charge(uint32_t duration) {
	// Rising phase.
	digitalWrite(chargePin, HIGH);
	uint32_t start = micros();
	// Forward readings while waiting.
	while (micros() - start < duration) {
		// Interrupt if time constant (63.2% of 1023) is reached.
		if (forward() >= 646)
			break;
	}
	return micros() - start;
}

void discharge(uint32_t duration) {
	// Falling phase.
	digitalWrite(chargePin, LOW);
	uint32_t start = micros();
	// Forward readings while waiting.
	while (micros() - start < duration) {
		forward();
	}
}

uint16_t forward() {
	uint16_t v = max(analogRead(feedbackPin), 1);
	uint8_t a = v >> 8;
	uint8_t b = v & 0xFF;
	// Forward readings while waiting.
	Serial.write(a);
	Serial.write(b);
	return v;
}