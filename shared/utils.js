// shared/utils.js - Common utility functions

// Timing-safe string comparison (to prevent timing attacks)
export function timingSafeEqual(a, b) {
  if (a.length !== b.length) {
    return false;
  }
  
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  
  return result === 0;
}

// Create a default trade message
export function createTradeMessage(data) {
  const { exchange, action, symbol, quantity, price } = data;
  let message = `📊 Trade Alert: ${action} ${symbol}\n`;
  message += `📈 Exchange: ${exchange}\n`;
  message += `💰 Quantity: ${quantity}\n`;
  
  if (price) {
    message += `💵 Price: ${price}\n`;
  }
  
  return message;
}
