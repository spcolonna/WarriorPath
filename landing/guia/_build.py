#!/usr/bin/env python3
"""Genera el centro de ayuda de Warrior Path.

Una sola plantilla + el contenido como datos: así las 9 guías quedan siempre
consistentes entre sí y se pueden regenerar de una cuando cambien las capturas
o los textos de la app.

Uso:  python3 landing/guia/_build.py
"""
import html
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))

# ── Contenido ────────────────────────────────────────────────────────────────
# Cada guía: slug, título, resumen (para el índice), "para qué sirve",
# prerrequisitos, pasos y consejos.
#
# En los textos se puede usar [[Texto]] para marcar un botón/campo tal como
# aparece en la app, y {{shot:nombre|epígrafe}} para insertar una captura.

GUIDES = [
    dict(
        slug="crear-escuela",
        title="Crear tu escuela",
        summary="El alta paso a paso: tu perfil, los datos de la escuela y la configuración inicial.",
        why="Es el primer paso y el que define todo lo demás. Al crear la escuela elegís qué "
            "artes marciales enseñás, y eso determina los niveles, las técnicas y hasta los "
            "colores que va a usar la app. Toma unos 10 minutos y se hace una sola vez.",
        pre=["Tener la app instalada y una cuenta creada (con Google, Apple o tu correo)."],
        steps=[
            dict(t="Completá tu perfil personal",
                 b="Después de crear tu cuenta, la app te pide tus datos: [[Nombre completo]], "
                   "teléfono, género y fecha de nacimiento. Son los datos del maestro, no de la escuela.",
                 shot="wizard-perfil"),
            dict(t="Cargá los datos de la escuela",
                 b="En [[Crear tu Escuela (Paso 2)]] va el [[Nombre de la escuela]] y elegís las "
                   "disciplinas que enseñás. Tenés que seleccionar **al menos una**.\n\n"
                   "Más abajo hay un bloque opcional con dirección, ciudad, teléfono y descripción. "
                   "Podés dejarlo vacío y completarlo después.",
                 shot="wizard-escuela"),
            dict(t="Configurá cada disciplina",
                 b="Por cada arte marcial que elegiste vas a definir dos cosas: los **niveles** "
                   "(cinturones o fajas) y las **técnicas**.\n\n"
                   "Buena noticia: la app **ya te carga la plantilla de tu arte marcial**, con los "
                   "cinturones y las técnicas armados. Sólo tenés que revisarlos y ajustar lo que "
                   "quieras cambiar.",
                 shot="wizard-disciplinas"),
            dict(t="Definí tus precios",
                 b="En [[Configurar precios]] elegís la moneda y cargás el precio de inscripción, "
                   "el de examen y los planes mensuales (por ejemplo: Básico, Intermedio, Avanzado).\n\n"
                   "Podés cambiarlos cuando quieras desde Gestión → Finanzas.",
                 shot="wizard-precios"),
            dict(t="Revisá y finalizá",
                 b="La última pantalla te muestra todo lo que cargaste para que lo confirmes. "
                   "Al finalizar, tu escuela queda creada.",
                 shot="wizard-revision"),
        ],
        tips=[
            dict(k="warn", t="Tu escuela necesita ser validada",
                 b="Después de crearla puede que veas una pantalla de espera en lugar del panel. "
                   "Es normal: las escuelas nuevas se validan o funcionan con el período de prueba. "
                   "Si te quedaste esperando más de lo razonable, escribinos."),
            dict(k="tip", t="No hace falta que quede perfecto de entrada",
                 b="Todo lo que cargues en el alta se puede editar después. Lo importante es "
                   "arrancar; los detalles los vas puliendo con la escuela ya andando."),
        ],
    ),
    dict(
        slug="configuracion",
        title="Configurar los datos de tu escuela",
        summary="Logo, dirección, ubicación en el mapa y las disciplinas que enseñás.",
        why="Es la cara de tu escuela dentro de la app. El logo y los datos son lo que ven tus "
            "alumnos, y la ubicación en el mapa es lo que permite que alumnos nuevos te encuentren "
            "cuando buscan escuelas cerca.",
        pre=["Tener la escuela ya creada."],
        steps=[
            dict(t="Entrá a los datos de la escuela",
                 b="Andá a la pestaña [[Gestión]] y tocá [[Editar Datos de la Escuela]].",
                 shot="config-menu"),
            dict(t="Subí el logo",
                 b="Tocá el ícono de cámara sobre el círculo y elegí una imagen de tu galería. "
                   "La app la comprime sola, así que no te preocupes por el peso del archivo.",
                 shot="config-logo"),
            dict(t="Completá los datos de contacto",
                 b="[[Nombre de la escuela]], [[Dirección]], [[Ciudad]], [[Teléfono]] y una "
                   "[[Descripción]] donde podés contar tu estilo, historia o a quién está dirigida.",
                 shot="config-datos"),
            dict(t="Marcá tu ubicación en el mapa",
                 b="Tocá el selector de ubicación y marcá dónde queda tu dojo. Es lo que hace que "
                   "aparezcas cuando un alumno busca escuelas en su zona.",
                 shot="config-mapa"),
            dict(t="Gestioná tus disciplinas",
                 b="Abajo tenés [[Gestionar Disciplinas]]: podés agregar artes marciales nuevas con "
                   "el botón `+`, o marcar como inactiva alguna que ya no enseñes.\n\n"
                   "Cuando termines, tocá [[Guardar Cambios]].",
                 shot="config-disciplinas"),
        ],
        tips=[
            dict(k="tip", t="Los colores de la app salen de tu disciplina",
                 b="Cada arte marcial tiene su color, y la app toma el de tu disciplina principal "
                   "para el tema visual. No hay un selector de color libre: si querés otro aspecto, "
                   "cambiá el orden de tus disciplinas."),
        ],
    ),
    dict(
        slug="curriculum",
        title="Armar tu currícula",
        summary="Niveles, cinturones y técnicas. Con plantillas listas para 14 artes marciales.",
        why="La currícula es el camino que van a recorrer tus alumnos: qué cinturones existen y "
            "qué técnicas corresponden a cada etapa. Una vez cargada, cada alumno ve su progreso y "
            "sabe qué le falta para el próximo nivel — que es lo que más los engancha.",
        pre=["Tener al menos una disciplina creada en tu escuela."],
        steps=[
            dict(t="Abrí el currículo",
                 b="Andá a [[Gestión]] → [[Gestionar Currículo]]. Si tenés una sola disciplina, "
                   "entra directo; si tenés varias, elegí cuál querés configurar.",
                 shot="curr-hub"),
            dict(t="Aplicá una plantilla (el atajo)",
                 b="Arriba a la derecha, el ícono de destellos ✨ aplica la plantilla de tu arte "
                   "marcial: trae los cinturones, las categorías y las técnicas ya armados.\n\n"
                   "Es seguro usarlo aunque ya tengas cosas cargadas: **sólo agrega lo que te "
                   "falta**, no borra ni reordena lo tuyo, y los alumnos con nivel asignado no se "
                   "ven afectados.\n\n"
                   "Hay plantillas de Karate, Taekwondo, Jiu Jitsu, Judo, Kung Fu, Tai Chi, Aikido, "
                   "Capoeira, Kendo, Krav Maga, Boxeo, Kickboxing, Muay Thai y MMA.",
                 shot="curr-plantilla"),
            dict(t="Ajustá los niveles",
                 b="En la pestaña [[Gestionar Niveles]] ponés el [[Nombre del Sistema de Progresión]] "
                   "(por ejemplo «Cinturones» o «Fajas») y editás la lista.\n\n"
                   "Podés **arrastrar** cada nivel para reordenarlo, cambiarle el nombre y elegirle "
                   "un color. Con [[Añadir Nivel]] agregás los que falten.",
                 shot="curr-niveles"),
            dict(t="Creá las categorías de técnicas",
                 b="Pasá a [[Gestionar Técnicas]]. Primero definís las categorías: por ejemplo "
                   "«Patadas», «Formas», «Defensa personal». Escribí el [[Nombre de la Categoría]] "
                   "y tocá `+`.",
                 shot="curr-categorias"),
            dict(t="Cargá las técnicas",
                 b="Ahora sí agregá cada técnica con su [[Nombre de la Técnica]], la categoría a la "
                   "que pertenece y, si querés, una descripción y un link de video.\n\n"
                   "Al terminar tocá [[Guardar Todos los Cambios]].",
                 shot="curr-tecnicas"),
        ],
        tips=[
            dict(k="warn", t="Las categorías van antes que las técnicas",
                 b="No vas a poder cargar una técnica si todavía no creaste ninguna categoría. "
                   "Es el orden que pide la app."),
            dict(k="tip", t="Empezá por la plantilla aunque no sea exacta",
                 b="Aplicar la plantilla y después ajustar es mucho más rápido que cargar todo a "
                   "mano. Podés borrar lo que no uses y agregar lo tuyo."),
        ],
    ),
    dict(
        slug="finanzas",
        title="Cobros y planes de pago",
        summary="Definí precios, asigná planes a tus alumnos y registrá los pagos.",
        why="Acá está el mayor ahorro de tiempo: en vez de perseguir las cuotas por WhatsApp, la "
            "app le avisa sola a cada alumno cuándo vence, y vos ves de un vistazo quién está al "
            "día y quién debe. También te queda el historial de todo lo cobrado.",
        pre=["Tener la escuela creada.", "Tener alumnos cargados para poder asignarles un plan."],
        steps=[
            dict(t="Configurá moneda, precios y día de vencimiento",
                 b="Andá a [[Gestión]] → [[Gestionar Finanzas]], pestaña **Planes y Precios**. "
                   "Elegí la moneda y cargá el precio de inscripción y el de examen.\n\n"
                   "Más abajo está el [[Día de vencimiento]]: el día del mes en que vencen las "
                   "cuotas. **De acá salen los avisos automáticos**, así que conviene ponerlo bien.",
                 shot="fin-precios"),
            dict(t="Creá tus planes de pago",
                 b="Con el botón `+` agregás un plan: [[Título del Plan]] (por ejemplo «Plan "
                   "Básico»), el [[Monto]] mensual y una descripción opcional.\n\n"
                   "Creá tantos como necesites: por cantidad de clases semanales, por edad, por lo "
                   "que uses en tu escuela. Al terminar, [[Guardar Cambios]].",
                 shot="fin-planes"),
            dict(t="Asigná un plan a cada alumno",
                 b="Andá a [[Alumnos]], entrá al alumno y en la pestaña **General** buscá la sección "
                   "de facturación. Tocá [[Cambiar plan asignado]] y elegí el plan.",
                 shot="fin-asignar"),
            dict(t="Registrá un pago",
                 b="En la ficha del alumno, pestaña **Pagos**, tocá [[Registrar Pago]].\n\n"
                   "Podés elegir [[Pago de Plan]] (toma el monto del plan asignado) o "
                   "[[Pago Especial]] para cosas puntuales como un examen o un seminario. Completá "
                   "[[Concepto]] y [[Monto]], la fecha, y guardá.",
                 shot="fin-registrar"),
            dict(t="Controlá quién debe",
                 b="En la pestaña [[Alumnos]] tenés filtros: **Al día**, **Vence hoy** y "
                   "**Atrasado**. Es tu panel de cobros del día a día.",
                 shot="fin-deudores"),
            dict(t="Mirá tus reportes",
                 b="De vuelta en [[Gestionar Finanzas]], la pestaña **Reportes** te muestra los "
                   "ingresos totales del año, un gráfico mensual y el detalle de cada pago.",
                 shot="fin-reportes"),
        ],
        tips=[
            dict(k="warn", t="Sin plan asignado no hay recordatorios",
                 b="Los avisos automáticos de vencimiento solo le llegan a los alumnos que tienen "
                   "un plan de pago asignado. Si a alguien no le llega nada, revisá eso primero."),
            dict(k="tip", t="Los recordatorios salen solos, dos veces",
                 b="La app le avisa a cada alumno el día anterior al vencimiento y de nuevo el "
                   "mismo día si todavía no pagó. Vos no tenés que hacer nada."),
        ],
    ),
    dict(
        slug="horarios",
        title="Cargar tus horarios de clase",
        summary="Definí qué clases das, qué días y en qué horario.",
        why="Los horarios son la base de la asistencia: cuando vas a pasar lista, la app te "
            "muestra las clases de hoy y elegís cuál. Además tus alumnos ven en su pantalla de "
            "inicio qué clases hay cada día.",
        pre=["Tener al menos una disciplina creada (si no, la app no te deja crear el horario)."],
        steps=[
            dict(t="Abrí la gestión de horarios",
                 b="Andá a [[Gestión]] → [[Gestionar Horarios]]. Vas a ver tus clases agrupadas por "
                   "día de la semana.",
                 shot="hor-lista"),
            dict(t="Agregá una clase",
                 b="Tocá el botón `+` para abrir [[Añadir Horario]].",
                 shot="hor-nuevo"),
            dict(t="Completá los datos",
                 b="Poné el [[Título de la Clase]] (por ejemplo «Clase Iniciantes»), elegí la "
                   "disciplina, marcá **todos los días** en que se dicta esa clase y definí "
                   "[[Hora de Inicio]] y [[Hora de Fin]].\n\n"
                   "Tocá [[Guardar Horario]].",
                 shot="hor-formulario"),
        ],
        tips=[
            dict(k="tip", t="Marcá todos los días de una",
                 b="Si tu clase de iniciantes es lunes y miércoles, marcá los dos días en el mismo "
                   "formulario. La app crea automáticamente el horario de cada día."),
            dict(k="warn", t="Los horarios no se editan",
                 b="Por ahora un horario solo se puede crear o borrar. Si te equivocaste en la hora, "
                   "borralo y creá uno nuevo."),
        ],
    ),
    dict(
        slug="alumnos",
        title="Gestionar tus alumnos",
        summary="Aceptar solicitudes, cargar alumnos sin app, cambiar roles y dar de baja.",
        why="Tus alumnos pueden llegar de dos formas: postulándose ellos desde la app, o cargados "
            "por vos si no la usan. Las dos conviven sin problema, así que no dependés de que todos "
            "tengan smartphone para llevar tu escuela ordenada.",
        pre=["Tener la escuela creada y validada."],
        steps=[
            dict(t="Revisá las solicitudes pendientes",
                 b="Cuando alguien se postula, te llega una notificación y aparece un punto rojo "
                   "sobre la pestaña [[Alumnos]]. También lo ves en la pantalla de inicio.",
                 shot="alu-pendientes"),
            dict(t="Aceptá o rechazá",
                 b="Tocá **Aceptar** para sumarlo. La app te pide en qué disciplina inscribirlo y lo "
                   "coloca automáticamente en el primer nivel.\n\n"
                   "Si rechazás, el alumno recibe un aviso y puede buscar otra escuela.",
                 shot="alu-aceptar"),
            dict(t="Cargá un alumno que no usa la app",
                 b="En la pestaña [[Alumnos]] tocá [[Agregar alumno]]. Completá el "
                   "[[Nombre del alumno]] (lo único obligatorio), y si querés su fecha de "
                   "nacimiento, género y teléfono.\n\n"
                   "Ese alumno funciona igual que el resto para asistencia, pagos y progreso.",
                 shot="alu-offline"),
            dict(t="Editá o dá de baja a un alumno",
                 b="Entrá a la ficha del alumno y usá el menú de los tres puntos, arriba a la "
                   "derecha. Ahí podés editar sus datos (si es un alumno sin app), cambiarle el rol "
                   "o inactivarlo.\n\n"
                   "Al inactivarlo deja de aparecer en las listas y el ranking, pero **se conserva "
                   "todo su historial**: si vuelve, lo reactivás y recupera su progreso intacto.",
                 shot="alu-menu"),
        ],
        tips=[
            dict(k="tip", t="Podés tener otro maestro",
                 b="Si compartís la escuela con otro profesor, cambiale el rol a Maestro desde el "
                   "menú de su ficha. Va a poder gestionar alumnos, cobros y progreso igual que vos, "
                   "pero no puede borrar la escuela ni cambiar el rol de otros maestros."),
            dict(k="warn", t="Eliminar es distinto de inactivar",
                 b="Inactivar conserva todo y es reversible. Eliminar borra el historial de ese "
                   "alumno en tu escuela y no se puede deshacer: si vuelve, tiene que postularse de "
                   "nuevo desde cero."),
        ],
    ),
    dict(
        slug="asistencia",
        title="Tomar asistencia",
        summary="Pasá lista en segundos desde el celular, o cargá una clase pasada.",
        why="Reemplaza el cuaderno. Te lleva menos de un minuto por clase y te queda el historial "
            "completo de cada alumno — así te das cuenta cuando alguien se empieza a ausentar, "
            "antes de que abandone.",
        pre=["Tener los horarios cargados.", "Tener alumnos activos en la escuela."],
        steps=[
            dict(t="Tocá «Tomar Asistencia»",
                 b="En la pantalla de [[Inicio]] tenés el botón [[Tomar Asistencia]]. La app busca "
                   "las clases de hoy y te pide que elijas cuál vas a registrar.",
                 shot="asi-boton"),
            dict(t="Marcá a los presentes",
                 b="Vas a ver la lista de alumnos. **Tocá cada uno para marcarlo presente o "
                   "ausente**. Arriba tenés el contador de presentes y una barra de progreso.\n\n"
                   "Si tenés muchos alumnos, usá el buscador o los filtros de Presentes / Ausentes.",
                 shot="asi-checklist"),
            dict(t="Listo, se guarda solo",
                 b="No hay botón de guardar: cada toque se registra al instante. Podés salir de la "
                   "pantalla cuando termines.",
                 shot=None),
            dict(t="¿Te olvidaste de una clase?",
                 b="Entrá a la ficha del alumno, pestaña **Asistencia**, y tocá "
                   "[[Registrar Asistencia Pasada]]. Elegís la fecha y la clase.",
                 shot="asi-pasada"),
        ],
        tips=[
            dict(k="tip", t="La asistencia suma poder",
                 b="Cada asistencia le da Nivel de Poder al alumno y lo hace subir en el ranking de "
                   "la escuela. Es lo que hace que quieran venir."),
        ],
    ),
    dict(
        slug="progreso",
        title="Progreso y promociones",
        summary="Asigná técnicas, seguí el avance y promové de cinturón.",
        why="Es el corazón de la app para el alumno: ver qué técnicas tiene asignadas, cuánto le "
            "falta y celebrar cuando sube de nivel. Para vos, es tener el progreso de cada uno "
            "ordenado en vez de en la memoria.",
        pre=["Tener la currícula cargada (niveles y técnicas).",
             "Tener al alumno inscripto en la disciplina."],
        steps=[
            dict(t="Inscribí al alumno en la disciplina",
                 b="Si el alumno todavía no está en ninguna disciplina, entrá a su ficha y usá "
                   "[[Inscribir en Disciplinas]]. Por cada disciplina aparece una pestaña propia de "
                   "progreso.",
                 shot="pro-inscribir"),
            dict(t="Asigná técnicas",
                 b="En la pestaña de progreso, tocá [[Asignar Técnicas]]. Vas a ver todas tus "
                   "técnicas agrupadas por categoría; marcá las que le tocan a ese alumno y guardá.\n\n"
                   "El alumno recibe una notificación y las ve en su app.",
                 shot="pro-tecnicas"),
            dict(t="Promové de nivel",
                 b="Cuando esté listo para el siguiente cinturón, tocá [[Promover Nivel]]. Elegí el "
                   "nuevo nivel y, si querés, dejá una nota (por ejemplo «Excelente progreso»).\n\n"
                   "Al alumno le llega la notificación con la felicitación.",
                 shot="pro-promover"),
            dict(t="Consultá el historial",
                 b="Debajo tenés el historial completo de promociones con sus notas y fechas. Si te "
                   "equivocaste, cada promoción se puede revertir.",
                 shot="pro-historial"),
        ],
        tips=[
            dict(k="tip", t="Las notas quedan registradas",
                 b="Aprovechá el campo de notas al promover: dentro de un año vas a agradecer tener "
                   "escrito por qué promoviste a cada alumno."),
        ],
    ),
    dict(
        slug="eventos",
        title="Eventos y seminarios",
        summary="Creá exámenes, seminarios o competencias e invitá a tus alumnos.",
        why="Sirve para exámenes de cinturón, seminarios, competencias o cualquier actividad fuera "
            "de la clase regular. Invitás a los alumnos desde la app, les llega la notificación y "
            "vos ves quién confirmó — sin listas de WhatsApp.",
        pre=["Tener alumnos activos en la escuela."],
        steps=[
            dict(t="Creá el evento",
                 b="Andá a [[Gestión]] → [[Gestionar Eventos]] y tocá `+` para abrir "
                   "[[Crear Nuevo Evento]].",
                 shot="eve-lista"),
            dict(t="Completá los datos",
                 b="[[Título del Evento]], las [[Disciplinas Involucradas]] (al menos una), la fecha "
                   "y el horario de inicio y fin.\n\n"
                   "La ubicación y el costo son opcionales — útiles para un seminario con cupo pago.",
                 shot="eve-formulario"),
            dict(t="Invitá a tus alumnos",
                 b="Al guardar, la app te lleva a elegir a quién invitar. Marcá los alumnos y "
                   "guardá: a cada uno le llega una notificación.",
                 shot="eve-invitar"),
            dict(t="Seguí las confirmaciones",
                 b="Entrá al evento y vas a ver la lista de invitados con su estado. Así sabés "
                   "cuántos van a venir antes del día.",
                 shot="eve-detalle"),
        ],
        tips=[
            dict(k="tip", t="Confirmar suma poder",
                 b="Cuando un alumno confirma que va a un evento, gana Nivel de Poder. Es un "
                   "incentivo extra para que participen."),
        ],
    ),
]


# ── Plantilla ────────────────────────────────────────────────────────────────
def fmt(text):
    """Convierte las marcas del contenido a HTML."""
    out = html.escape(text)
    out = re.sub(r"\[\[(.+?)\]\]", r'<span class="ui">\1</span>', out)
    out = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", out)
    out = re.sub(r"`(.+?)`", r'<span class="ui">\1</span>', out)
    return "".join(f"<p>{p}</p>" for p in out.split("\n\n"))


def shot(name, caption=""):
    if not name:
        return ""
    path = os.path.join(HERE, "..", "assets", "guia", f"{name}.webp")
    cap = f'<figcaption>{html.escape(caption)}</figcaption>' if caption else ""
    if os.path.exists(path):
        return (f'<figure><img src="../assets/guia/{name}.webp" alt="{html.escape(caption or name)}"'
                f' loading="lazy">{cap}</figure>')
    # Sin captura todavía: hueco visible pero prolijo.
    return (f'<figure><div class="shot-todo">Captura pendiente<br><small>{name}</small></div>'
            f'{cap}</figure>')


HEAD = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title} — Guía de Warrior Path</title>
<meta name="description" content="{desc}">
<link rel="stylesheet" href="{css}">
</head>
<body>
<header>
  <div class="wrap">
    <span class="logo">🥋</span>
    <a class="brand" href="../index.html">Warrior Path</a>
    <nav>
      <a href="index.html">Guías</a>
      <a href="../support.html">Soporte</a>
    </nav>
  </div>
</header>
"""

FOOT = """<footer>
  <div class="wrap">
    <p>© 2026 Warrior Path · <a href="../index.html">Inicio</a> ·
       <a href="../support.html">Soporte</a> ·
       <a href="../privacy.html">Privacidad</a></p>
  </div>
</footer>
</body>
</html>
"""


def build_index():
    cards = []
    for i, g in enumerate(GUIDES, 1):
        cards.append(
            f'<a class="card" href="{g["slug"]}.html">'
            f'<span class="num">{i}</span>'
            f'<h3>{html.escape(g["title"])}</h3>'
            f'<p>{html.escape(g["summary"])}</p></a>'
        )
    body = f"""<div class="hero">
  <div class="wrap">
    <h1>Guía de uso para maestros</h1>
    <p>Todo lo que podés hacer con Warrior Path, explicado paso a paso.
       Están ordenadas como las vas a necesitar: si recién empezás, seguilas en orden.</p>
  </div>
</div>
<main>
  <div class="wrap">
    <div class="grid">{''.join(cards)}</div>
    <div class="tip" style="margin-top:32px">
      <strong>¿No encontrás lo que buscabas?</strong>
      Escribinos desde la <a href="../support.html">página de soporte</a> y te ayudamos.
    </div>
  </div>
</main>"""
    out = HEAD.format(title="Guía de uso", css="guia.css",
                      desc="Guía paso a paso de Warrior Path para maestros de artes marciales.") \
        + body + FOOT
    with open(os.path.join(HERE, "index.html"), "w", encoding="utf-8") as f:
        f.write(out)


def build_guide(i, g):
    prev_g = GUIDES[i - 1] if i > 0 else None
    next_g = GUIDES[i + 1] if i < len(GUIDES) - 1 else None

    steps = []
    for n, s in enumerate(g["steps"], 1):
        steps.append(
            f'<div class="step"><div class="step-head">'
            f'<span class="step-num">{n}</span><h3>{html.escape(s["t"])}</h3></div>'
            f'<div class="step-body">{fmt(s["b"])}{shot(s.get("shot"), s["t"])}</div></div>'
        )

    pre = ""
    if g.get("pre"):
        items = "".join(f"<li>{html.escape(p)}</li>" for p in g["pre"])
        pre = f'<div class="pre"><h3>Antes de empezar</h3><ul>{items}</ul></div>'

    tips = "".join(
        f'<div class="{t["k"]}"><strong>{html.escape(t["t"])}</strong>{fmt(t["b"])}</div>'
        for t in g.get("tips", [])
    )

    nav = ['<a href="index.html"><b>Volver</b>Todas las guías</a>']
    if next_g:
        nav.append(f'<a href="{next_g["slug"]}.html"><b>Siguiente</b>{html.escape(next_g["title"])}</a>')
    elif prev_g:
        nav.append(f'<a href="{prev_g["slug"]}.html"><b>Anterior</b>{html.escape(prev_g["title"])}</a>')

    body = f"""<div class="hero">
  <div class="wrap">
    <div class="crumbs"><a href="index.html">Guías</a> › {html.escape(g["title"])}</div>
    <h1>{html.escape(g["title"])}</h1>
  </div>
</div>
<main>
  <div class="wrap">
    <div class="lead"><h2>¿Para qué sirve?</h2><p>{html.escape(g["why"])}</p></div>
    {pre}
    <h2 class="sec">Paso a paso</h2>
    {''.join(steps)}
    {tips}
    <div class="next">{''.join(nav)}</div>
  </div>
</main>"""

    out = HEAD.format(title=html.escape(g["title"]), css="guia.css",
                      desc=html.escape(g["summary"])) + body + FOOT
    with open(os.path.join(HERE, f'{g["slug"]}.html'), "w", encoding="utf-8") as f:
        f.write(out)


if __name__ == "__main__":
    build_index()
    for i, g in enumerate(GUIDES):
        build_guide(i, g)
    print(f"Generadas {len(GUIDES) + 1} páginas en {HERE}")
