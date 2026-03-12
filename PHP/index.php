<?php
session_start();
include 'conexion.php';

$error = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $nombre = $_POST['nombre'];
    $password = $_POST['password'];
 
    // Buscamos solo por nombre y traemos el hash para verificarlo luego con PHP.
    $sql = "SELECT id, nombre, password, rol FROM usuarios WHERE nombre = '$nombre'";
    $resultado = mysqli_query($conexion, $sql);

    if (mysqli_num_rows($resultado) == 1) {
        $usuario = mysqli_fetch_assoc($resultado);

        // Aquí comparamos la clave en texto plano con el hash de la BD
        if (password_verify($password, $usuario['password'])) {
            
            $_SESSION['usuario_id'] = $usuario['id'];
            $_SESSION['nombre'] = $usuario['nombre'];
            $_SESSION['rol'] = $usuario['rol'];

            // Filtro para mandar a Andrés al panel general y a Salva/Dani al de usuario
            if ($usuario['rol'] == 'admin') {
                header("Location: admin.php");
            } else {
                header("Location: mis_incidencias.php");
            }
            exit(); 
            
        } else {
            $error = "Contraseña incorrecta";
        }
    } else {
        $error = "El usuario no existe";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Login - Gestor de Incidencias</title>
</head>
<body>
    <h2>Acceso al gestor de incidencias</h2>

    <form method="POST" action="">
        <label>Usuario:</label><br>
        <input type="text" name="nombre" required><br><br>
        
        <label>Contraseña:</label><br>
        <input type="password" name="password" required><br><br>
        
        <button type="submit">Entrar</button>
    </form>
    <?php if($error != "") echo "<p style='color:red;'>$error</p>"; ?>
</body>
</html>
