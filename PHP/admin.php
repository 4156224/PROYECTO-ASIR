<?php
session_start();
include 'conexion.php';

// Si no está logueado o no es admin, lo echamos
if (!isset($_SESSION['usuario_id']) || $_SESSION['rol'] != 'admin') {
    header("Location: index.php");
    exit();
}

// 1. MARCAR COMO RESUELTA LA INCIDENCIA
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['resolver_id'])) {
    $id_resolver = $_POST['resolver_id'];
    $sql_update = "UPDATE incidencias SET estado = 'resuelta' WHERE id = '$id_resolver'";
    mysqli_query($conexion, $sql_update);
}

// 2. LÓGICA PARA CREAR UN NUEVO USUARIO DESDE EL PANEL
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['crear_usuario'])) {
    $nuevo_nombre = mysqli_real_escape_string($conexion, $_POST['nuevo_nombre']);
    $nueva_pass_plana = $_POST['nueva_pass'];
    
    // AQUÍ HASHEAMOS LA CONTRASEÑA NUEVA AUTOMÁTICAMENTE
    $nueva_pass_hash = password_hash($nueva_pass_plana, PASSWORD_DEFAULT);
    $nuevo_rol = $_POST['nuevo_rol'];

    $sql_user = "INSERT INTO usuarios (nombre, password, rol) VALUES ('$nuevo_nombre', '$nueva_pass_hash', '$nuevo_rol')";
    if(mysqli_query($conexion, $sql_user)){
        $mensaje_admin = "Usuario '$nuevo_nombre' creado con éxito.";
    } else {
        $mensaje_admin = "Error al crear usuario (quizás el nombre ya existe).";
    }
}

// 3. LEER TODAS LAS INCIDENCIAS (Cruzando datos con la tabla usuarios)
$sql_todas = "SELECT incidencias.*, usuarios.nombre AS creador 
              FROM incidencias 
              JOIN usuarios ON incidencias.usuario_id = usuarios.id 
              ORDER BY estado ASC, fecha_creacion DESC";
$resultado = mysqli_query($conexion, $sql_todas);
?>

<!DOCTYPE html>
<html>
<head><title>Panel de Administración</title></head>
<body>
    <h2>Panel de Control - Administrador: <?php echo $_SESSION['nombre']; ?></h2>
    <a href="logout.php">Cerrar Sesión</a>
    <hr>
    <div style="margin-bottom: 30px;">

    <h3>Crear Nuevo Usuario</h3>
        <form method="POST" action="" style="display: flex; gap: 10px; align-items: center;">
            <input type="text" name="nuevo_nombre" placeholder="Nombre del usuario" required style="width: 200px; margin: 0; padding: 8px;">
            <input type="password" name="nueva_pass" placeholder="Contraseña" required style="width: 200px; margin: 0; padding: 8px;">
            <select name="nuevo_rol" style="margin: 0; padding: 8px;">
                <option value="usuario">Usuario</option>
                <option value="admin">Administrador</option>
            </select>
            <button type="submit" name="crear_usuario" style="margin: 0; padding: 7px 15px;">➕ Registrar</button>
        </form>
	<?php if(isset($mensaje_admin)) echo "<p style='color:blue;'><b>$mensaje_admin</b></p>"; ?>
    </div>
    <hr>
    <div style="margin-bottom: 30px;">

    <h3>Todas las Incidencias del Sistema</h3>
    <table border="1" cellpadding="5">
        <tr>
            <th>ID</th>
            <th>Usuario</th>
            <th>IP Origen</th>
            <th>Título</th>
            <th>Descripción</th>
            <th>Estado</th>
            <th>Acción</th>
        </tr>
        <?php while ($fila = mysqli_fetch_assoc($resultado)) { ?>
            <tr>
                <td><?php echo $fila['id']; ?></td>
                <td><b><?php echo $fila['creador']; ?></b></td>
                <td><?php echo $fila['ip_usuario']; ?></td>
                <td><?php echo $fila['titulo']; ?></td>
                <td><?php echo $fila['descripcion']; ?></td>
                <td style="color: <?php echo ($fila['estado'] == 'pendiente') ? 'red' : 'green'; ?>">
                    <b><?php echo strtoupper($fila['estado']); ?></b>
                </td>
                <td>
                    <?php if ($fila['estado'] == 'pendiente') { ?>
                        <form method="POST" action="">
                            <input type="hidden" name="resolver_id" value="<?php echo $fila['id']; ?>">
                            <button type="submit">✔ Marcar Resuelta</button>
                        </form>
                    <?php } else { echo "Completada"; } ?>
                </td>
            </tr>
        <?php } ?>
    </table>
</body>
</html>
