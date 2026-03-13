<?php
session_start();
include 'conexion.php';

// Si no hay sesión iniciada, lo mandamos al login
if (!isset($_SESSION['usuario_id'])) {
    header("Location: index.php");
    exit();
}

$mi_id = $_SESSION['usuario_id'];
$mi_nombre = strtoupper($_SESSION['nombre']);

// 1. GUARDAR UNA NUEVA INCIDENCIA
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['crear'])) {
    $titulo = mysqli_real_escape_string($conexion, $_POST['titulo']);
    $descripcion = mysqli_real_escape_string($conexion, $_POST['descripcion']);
    $ip = $_SERVER['REMOTE_ADDR']; // Capturamos la IP automáticamente

    $sql_insert = "INSERT INTO incidencias (titulo, descripcion, ip_usuario, usuario_id) 
                   VALUES ('$titulo', '$descripcion', '$ip', '$mi_id')";

    if (mysqli_query($conexion, $sql_insert)) {
        $mensaje = "¡Incidencia creada con éxito!";

        // --- AVISO POR TELEGRAM MEDIANTE PYTHON ---
        $texto_aviso = "🚨 NUEVA INCIDENCIA DE $mi_nombre\nProblema: $titulo\nDescripcion del problema:\n$descripcion";
        $argumento_seguro = escapeshellarg($texto_aviso);
        shell_exec("python3 /var/www/html/bot.py $argumento_seguro");
        // -----------------------------------------
        // Guardamos el mensaje en la SESIÓN para que no se borre al redireccionar
        $_SESSION['mensaje_exito'] = "¡Incidencia creada con éxito y enviada a Telegram!";
        // Redireccionamos a la misma página para "limpiar" el POST
        header("Location: mis_incidencias.php");
        exit();
    }
}

// 2. LEER MIS INCIDENCIAS
$sql_leer = "SELECT * FROM incidencias WHERE usuario_id = '$mi_id' ORDER BY fecha_creacion DESC";
$resultado = mysqli_query($conexion, $sql_leer);
?>

<!DOCTYPE html>
<html>
<head><title>Mis Incidencias</title></head>
<body>
    <h2>BIENVENIDO, USUARIO <?php echo $mi_nombre; ?></h2>
    <a href="logout.php">Cerrar Sesión</a>
    <hr>

    <h3>Reportar un nuevo problema</h3>    
    <form method="POST" action="" style="max-width: 400px;">
        <input type="text" name="titulo" placeholder="Título (ej: PC no enciende)" required 
               style="width: 100%; padding: 10px; margin-bottom: 10px; box-sizing: border-box;">
        <br>
        <textarea name="descripcion" placeholder="Explica el problema..." required 
                  style="width: 100%; height: 120px; padding: 10px; margin-bottom: 10px; box-sizing: border-box; font-family: Arial, sans-serif;"></textarea>
        <br>
        <button type="submit" name="crear" style="padding: 10px 20px; cursor: pointer;">Enviar Incidencia</button>
        <?php 
        if(isset($_SESSION['mensaje_exito'])) {
            echo "<p style='color:green; font-weight: bold; margin-top: 15px;'>" . $_SESSION['mensaje_exito'] . "</p>";
            unset($_SESSION['mensaje_exito']); // Lo borramos para que no salga siempre
        } 
        ?>
    </form>

    <hr>

    <h3>Mi Historial de Incidencias</h3>
    <table border="1" cellpadding="5">
        <tr>
            <th>ID</th>
            <th>Título</th>
            <th>Descripción</th>
            <th>Estado</th>
            <th>Fecha</th>
        </tr>
        <?php while ($fila = mysqli_fetch_assoc($resultado)) { ?>
            <tr>
                <td><?php echo $fila['id']; ?></td>
                <td><?php echo $fila['titulo']; ?></td>
                <td><?php echo $fila['descripcion']; ?></td>
                <td style="color: <?php echo ($fila['estado'] == 'pendiente') ? 'red' : 'green'; ?>">
                    <b><?php echo strtoupper($fila['estado']); ?></b>
                </td>
                <td><?php echo $fila['fecha_creacion']; ?></td>
            </tr>
        <?php } ?>
    </table>
</body>
</html>
