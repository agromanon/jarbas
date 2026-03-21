#!/usr/bin/env node
/**
 * Test script for weather handler
 * Tests the weather forecast functionality without sending Telegram messages
 */

const { spawn } = require('child_process');

async function testForecastScript(type) {
  console.log(`\n=== Testing forecast script: ${type} ===`);

  return new Promise((resolve, reject) => {
    const child = spawn('/job/skills/weather-forecast/forecast.sh', [type, 'true'], {
      env: {
        ...process.env
      }
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    child.on('close', (code) => {
      if (code !== 0) {
        console.error(`❌ Error: Script exited with code ${code}`);
        console.error('stderr:', stderr);
        reject(new Error(stderr));
        return;
      }

      try {
        const result = JSON.parse(stdout.trim());
        console.log('✓ Forecast generated successfully');
        console.log('Message preview (first 200 chars):');
        console.log(result.message.substring(0, 200) + '...');
        resolve(result);
      } catch (error) {
        console.error('❌ Failed to parse JSON:', error.message);
        console.error('stdout:', stdout);
        reject(error);
      }
    });
  });
}

async function main() {
  console.log('🌤️  Weather Forecast Test Suite');
  console.log('================================');

  const types = ['today', 'tomorrow', '3days', '7days'];

  for (const type of types) {
    try {
      await testForecastScript(type);
    } catch (error) {
      console.error(`❌ Failed to test ${type}:`, error.message);
    }
  }

  console.log('\n✅ All tests completed!');
}

main().catch(console.error);
