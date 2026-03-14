import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Política de Privacidad",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  "RightJob",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Política de Privacidad",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Versión 1.0 — Marzo 2026",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _intro("En RightJob nos importa tu privacidad. Esta política explica de manera clara y sencilla qué información recopilamos, cómo la usamos y cómo la protegemos. Al usar nuestra plataforma, aceptas los términos descritos aquí."),

          _section("1. ¿Quiénes somos?", Icons.info_outline_rounded, [
            _para("RightJob es una plataforma digital que conecta a candidatos en búsqueda de empleo con empresas que tienen vacantes disponibles. Funcionamos como un espacio de encuentro profesional donde ambas partes pueden conocerse, hacer match y comunicarse directamente."),
            _para("Somos responsables del tratamiento de tus datos personales conforme a lo establecido en esta política y en la legislación aplicable de protección de datos."),
          ]),

          _section("2. ¿Qué datos recopilamos?", Icons.list_alt_rounded, [
            _subtitle("2.1 Datos que tú nos proporcionas"),
            _para("Al registrarte y usar RightJob, recopilamos la siguiente información:"),
            _bullets([
              "Nombre completo",
              "Correo electrónico",
              "Número de teléfono (visible solo tras un match mutuo)",
              "Foto de perfil",
              "Profesión, área de trabajo y nivel de estudios",
              "Expectativa salarial",
              "Biografía o descripción profesional",
              "Perfil de LinkedIn y sitio web (opcional)",
              "Documentos adjuntos como CV en formato PDF (solo en chat, tras match)",
            ]),
            _subtitle("2.2 Datos que recopilamos automáticamente"),
            _bullets([
              "Tipo de dispositivo y navegador",
              "Dirección IP aproximada",
              "Actividad dentro de la plataforma (swipes, matches, mensajes enviados)",
            ]),
            _subtitle("2.3 Datos de terceros"),
            _para("Si inicias sesión con Google, recibimos tu nombre, correo y foto de perfil desde tu cuenta de Google, conforme a sus propias políticas de privacidad."),
          ]),

          _section("3. ¿Para qué usamos tus datos?", Icons.settings_outlined, [
            _para("Usamos tu información únicamente para los siguientes fines:"),
            _bullets([
              "Crear y gestionar tu perfil en la plataforma",
              "Mostrarte perfiles relevantes según tu rol",
              "Facilitar el sistema de match y conexiones profesionales",
              "Permitirte chatear con tus matches",
              "Enviarte notificaciones dentro de la app",
              "Mejorar la experiencia y funcionalidad de la plataforma",
              "Garantizar la seguridad y prevenir usos fraudulentos",
            ]),
            _highlight("Nunca vendemos, alquilamos ni compartimos tu información personal con terceros con fines comerciales."),
          ]),

          _section("4. ¿Quién puede ver tu información?", Icons.visibility_outlined, [
            _subtitle("4.1 Información pública en tu perfil"),
            _bullets([
              "Nombre y foto de perfil",
              "Profesión o rol",
              "Biografía y habilidades",
              "Nivel de estudios",
              "Rango salarial esperado",
            ]),
            _subtitle("4.2 Información privada (solo tras match mutuo)"),
            _bullets([
              "Correo electrónico",
              "Número de teléfono",
              "Documentos adjuntos compartidos en el chat",
            ]),
            _subtitle("4.3 Proveedores de servicio"),
            _bullets([
              "Firebase (Google) — autenticación, base de datos y almacenamiento seguro",
              "Netlify — alojamiento de la aplicación web",
            ]),
          ]),

          _section("5. ¿Cómo protegemos tus datos?", Icons.lock_outline_rounded, [
            _bullets([
              "Cifrado en tránsito mediante HTTPS en todas las comunicaciones",
              "Almacenamiento en Firebase con cifrado en reposo",
              "Acceso restringido mediante reglas de seguridad de Firestore",
              "Autenticación segura con Firebase Auth",
              "Sin almacenamiento de contraseñas en texto plano",
            ]),
            _para("Si bien ningún sistema es 100% infalible, tomamos todas las medidas razonables para mantener tu información segura."),
          ]),

          _section("6. Tus derechos", Icons.verified_user_outlined, [
            _bullets([
              "Acceso — consultar qué información tenemos sobre ti",
              "Rectificación — corregir o actualizar tu información desde tu perfil",
              "Eliminación — solicitar la eliminación completa de tu cuenta y datos",
              "Portabilidad — solicitar una copia de tus datos",
              "Oposición — oponerte al uso de tus datos para ciertos fines",
            ]),
            _para("Para ejercer cualquiera de estos derechos, contáctanos en el correo indicado al final de este documento."),
          ]),

          _section("7. ¿Cuánto tiempo conservamos tus datos?", Icons.access_time_rounded, [
            _para("Conservamos tu información mientras tu cuenta esté activa. Si eliminas tu cuenta:"),
            _bullets([
              "Tu perfil y datos personales se eliminan de forma permanente",
              "Los mensajes de chat asociados también se eliminan",
              "Podemos conservar datos anonimizados con fines estadísticos",
            ]),
          ]),

          _section("8. Menores de edad", Icons.child_care_rounded, [
            _para("RightJob es una plataforma diseñada para uso profesional y laboral. No está dirigida a menores de 18 años. Si detectamos que un usuario menor de edad se ha registrado, procederemos a eliminar su cuenta y datos de forma inmediata."),
          ]),

          _section("9. Cambios a esta política", Icons.update_rounded, [
            _para("Podemos actualizar esta política ocasionalmente. Cuando lo hagamos, notificaremos a los usuarios mediante un aviso dentro de la plataforma y actualizaremos la fecha de versión."),
          ]),

          _section("10. ¿Tienes preguntas?", Icons.mail_outline_rounded, [
            _bullets([
              "Plataforma: rightjob.netlify.app",
              "Correo: privacidad@rightjob.app",
            ]),
            _highlight("Agradecemos tu confianza en RightJob. Nos comprometemos a proteger tu información y a ser siempre transparentes sobre cómo la usamos."),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _intro(String text) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.6, fontStyle: FontStyle.italic)),
  );

  Widget _section(String title, IconData icon, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF1565C0), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    ),
  );

  Widget _subtitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
  );

  Widget _para(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.6)),
  );

  Widget _bullets(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items.map((item) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: CircleAvatar(radius: 3, backgroundColor: Color(0xFF1565C0)),
          ),
          Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5))),
        ],
      ),
    )).toList(),
  );

  Widget _highlight(String text) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF1565C0).withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF1565C0), height: 1.5, fontStyle: FontStyle.italic)),
  );
}