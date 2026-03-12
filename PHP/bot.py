import sys
import requests

# Pon aquí tus datos reales entre las comillas
TOKEN = "8710687695:AAHzcVbn_B6hOpB1o42_xzIwRyyOCHcptZg"
CHAT_ID = "948262347"

# El mensaje nos llegará desde PHP como el primer argumento (sys.argv[1])
mensaje = sys.argv[1]

# Montamos la URL de la API de Telegram
url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
datos = {
    "chat_id": CHAT_ID,
    "text": mensaje
}

# Mandamos la petición de forma silenciosa
try:
    requests.post(url, data=datos)
except Exception as e:
    print(f"Error al enviar: {e}")
