#!/usr/bin/env python3
"""
IoT Simulator for Entrance Cockpit System
Simulates entrance sensors sending data via MQTT
"""

import os
import time
import random
import json
from datetime import datetime
import paho.mqtt.client as mqtt

# Configuration MQTT
MQTT_BROKER = os.getenv('MQTT_BROKER', 'mosquitto')
MQTT_PORT = int(os.getenv('MQTT_PORT', '1883'))
MQTT_USER = os.getenv('MQTT_USER', '')
MQTT_PASSWORD = os.getenv('MQTT_PASSWORD', '')
MQTT_TOPIC_BASE = os.getenv('MQTT_TOPIC_BASE', 'entrance/sensors')

# Configuration des capteurs simulés
SENSORS = [
    {
        'id': 'entrance_001',
        'name': 'Main Entrance Sensor',
        'location': 'Building A - Main Door',
        'type': 'motion'
    },
    {
        'id': 'entrance_002',
        'name': 'Side Entrance Sensor',
        'location': 'Building A - Side Door',
        'type': 'motion'
    },
    {
        'id': 'entrance_003',
        'name': 'Temperature Sensor',
        'location': 'Building A - Lobby',
        'type': 'temperature'
    },
    {
        'id': 'entrance_004',
        'name': 'Humidity Sensor',
        'location': 'Building A - Lobby',
        'type': 'humidity'
    }
]

class EntranceSensorSimulator:
    def __init__(self):
        self.client = mqtt.Client(client_id="entrance_simulator")
        self.connected = False

        # Configuration des callbacks
        self.client.on_connect = self.on_connect
        self.client.on_disconnect = self.on_disconnect

        # Authentification si nécessaire
        if MQTT_USER and MQTT_PASSWORD:
            self.client.username_pw_set(MQTT_USER, MQTT_PASSWORD)

    def on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            print(f"✅ Connected to MQTT Broker at {MQTT_BROKER}:{MQTT_PORT}")
            self.connected = True
        else:
            print(f"❌ Failed to connect, return code {rc}")
            self.connected = False

    def on_disconnect(self, client, userdata, rc):
        print(f"⚠️  Disconnected from MQTT Broker (code: {rc})")
        self.connected = False

    def connect(self):
        """Connect to MQTT broker with retry logic"""
        max_retries = 5
        retry_delay = 5

        for attempt in range(max_retries):
            try:
                print(f"🔌 Connecting to MQTT Broker {MQTT_BROKER}:{MQTT_PORT} (attempt {attempt + 1}/{max_retries})...")
                self.client.connect(MQTT_BROKER, MQTT_PORT, 60)
                self.client.loop_start()

                # Wait for connection
                timeout = 10
                start_time = time.time()
                while not self.connected and (time.time() - start_time) < timeout:
                    time.sleep(0.5)

                if self.connected:
                    return True

            except Exception as e:
                print(f"❌ Connection attempt {attempt + 1} failed: {e}")

            if attempt < max_retries - 1:
                print(f"⏳ Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)

        return False

    def generate_motion_data(self, sensor):
        """Generate motion sensor data"""
        motion_detected = random.choice([True, False, False, False])  # 25% chance
        return {
            'sensor_id': sensor['id'],
            'sensor_name': sensor['name'],
            'location': sensor['location'],
            'type': sensor['type'],
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'data': {
                'motion_detected': motion_detected,
                'count': random.randint(0, 5) if motion_detected else 0
            }
        }

    def generate_temperature_data(self, sensor):
        """Generate temperature sensor data"""
        return {
            'sensor_id': sensor['id'],
            'sensor_name': sensor['name'],
            'location': sensor['location'],
            'type': sensor['type'],
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'data': {
                'temperature': round(random.uniform(18.0, 26.0), 2),
                'unit': 'celsius'
            }
        }

    def generate_humidity_data(self, sensor):
        """Generate humidity sensor data"""
        return {
            'sensor_id': sensor['id'],
            'sensor_name': sensor['name'],
            'location': sensor['location'],
            'type': sensor['type'],
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'data': {
                'humidity': round(random.uniform(30.0, 70.0), 2),
                'unit': 'percent'
            }
        }

    def generate_sensor_data(self, sensor):
        """Generate data based on sensor type"""
        if sensor['type'] == 'motion':
            return self.generate_motion_data(sensor)
        elif sensor['type'] == 'temperature':
            return self.generate_temperature_data(sensor)
        elif sensor['type'] == 'humidity':
            return self.generate_humidity_data(sensor)
        else:
            return None

    def publish_sensor_data(self, sensor):
        """Publish sensor data to MQTT topic"""
        if not self.connected:
            print("⚠️  Not connected to MQTT broker")
            return False

        data = self.generate_sensor_data(sensor)
        if data is None:
            return False

        topic = f"{MQTT_TOPIC_BASE}/{sensor['id']}"
        payload = json.dumps(data)

        try:
            result = self.client.publish(topic, payload, qos=1)
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"📤 [{sensor['id']}] Published: {data['data']}")
                return True
            else:
                print(f"❌ Failed to publish to {topic}")
                return False
        except Exception as e:
            print(f"❌ Error publishing data: {e}")
            return False

    def run(self):
        """Main simulation loop"""
        print("\n" + "="*50)
        print("🚀 Entrance Cockpit IoT Simulator")
        print("="*50)
        print(f"📍 Simulating {len(SENSORS)} sensors")
        print(f"📡 MQTT Broker: {MQTT_BROKER}:{MQTT_PORT}")
        print(f"📢 Topic Base: {MQTT_TOPIC_BASE}")
        print("="*50 + "\n")

        # Connect to MQTT broker
        if not self.connect():
            print("❌ Failed to connect to MQTT broker. Exiting.")
            return

        print("\n✅ Simulation started. Press Ctrl+C to stop.\n")

        try:
            iteration = 0
            while True:
                iteration += 1
                print(f"\n--- Iteration {iteration} ---")

                # Publish data for each sensor
                for sensor in SENSORS:
                    self.publish_sensor_data(sensor)
                    time.sleep(0.5)  # Small delay between sensors

                # Wait before next iteration
                time.sleep(5)

        except KeyboardInterrupt:
            print("\n\n⏹️  Simulation stopped by user")
        except Exception as e:
            print(f"\n❌ Error during simulation: {e}")
        finally:
            self.client.loop_stop()
            self.client.disconnect()
            print("👋 Disconnected from MQTT broker")

if __name__ == "__main__":
    simulator = EntranceSensorSimulator()
    simulator.run()
