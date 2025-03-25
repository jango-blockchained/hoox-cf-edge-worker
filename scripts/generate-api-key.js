// scripts/generate-api-key.js - Script to generate secure API keys

// Generate a secure API key
function generateSecureKey(length = 32) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  const randValues = new Uint8Array(length);
  crypto.getRandomValues(randValues);
  
  for (let i = 0; i < length; i++) {
    result += characters.charAt(randValues[i] % characters.length);
  }
  
  return result;
}

console.log('Generated API Key:', generateSecureKey(48));
console.log('Generated Internal Service Key:', generateSecureKey(64));
