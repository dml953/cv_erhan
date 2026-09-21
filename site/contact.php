<?php
/**
 * Traitement du formulaire de contact du portfolio.
 *
 * Remplace l'ancien envoi vers wp-admin/admin-post.php, qui ne fonctionne
 * plus une fois le site sorti de WordPress.
 *
 * Nécessite PHP-FPM côté serveur (déjà requis par Dotclear) et un agent
 * de courrier local (Postfix en mode « local only » suffit).
 */

declare(strict_types=1);

// ── Configuration ────────────────────────────────────────────────────────
const MAIL_TO        = 'dumluerhan@yahoo.com';
const MAIL_FROM      = 'contact@mon-domaine.fr';   // doit appartenir au domaine (SPF)
const MAIL_SUBJECT   = 'Portfolio — nouveau message';
const MIN_SECONDS    = 30;                          // délai minimum entre 2 envois
const MAX_MESSAGE    = 4000;

/**
 * Répond en JSON à une requête fetch(), sinon renvoie l'utilisateur vers la
 * page d'accueil avec un paramètre d'état (formulaire sans JavaScript).
 */
function respond(bool $ok, string $message, int $status = 200): never
{
    $accept = $_SERVER['HTTP_ACCEPT'] ?? '';

    if (str_contains($accept, 'application/json')) {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['ok' => $ok, 'message' => $message], JSON_UNESCAPED_UNICODE);
        exit;
    }

    header('Location: /?contact=' . ($ok ? 'ok' : 'erreur') . '#contact', true, 303);
    exit;
}

/**
 * Neutralise les retours à la ligne : sans cela, une valeur contrôlée par le
 * visiteur et recopiée dans un en-tête permet d'injecter des en-têtes
 * supplémentaires (Bcc, etc.) et de transformer le formulaire en relais de spam.
 */
function headerSafe(string $value): string
{
    return trim(str_replace(["\r", "\n", "\0", '%0a', '%0d'], ' ', $value));
}

// ── Garde-fous ───────────────────────────────────────────────────────────
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    respond(false, 'Méthode non autorisée.', 405);
}

// Champ piège : seul un robot le remplit.
if (trim((string) ($_POST['website'] ?? '')) !== '') {
    // On répond « ok » pour ne pas renseigner le robot sur la détection.
    respond(true, 'Message envoyé. Merci !');
}

// Limitation de fréquence par session (anti-flood basique).
session_start();
$now  = time();
$last = (int) ($_SESSION['contact_last'] ?? 0);
if ($now - $last < MIN_SECONDS) {
    respond(false, 'Merci de patienter quelques instants avant un nouvel envoi.', 429);
}

// ── Validation ───────────────────────────────────────────────────────────
$prenom  = trim((string) ($_POST['prenom']  ?? ''));
$nom     = trim((string) ($_POST['nom']     ?? ''));
$email   = trim((string) ($_POST['email']   ?? ''));
$message = trim((string) ($_POST['message'] ?? ''));

$errors = [];

if ($prenom === '' || mb_strlen($prenom) > 80) {
    $errors[] = 'prénom';
}
if ($nom === '' || mb_strlen($nom) > 80) {
    $errors[] = 'nom';
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($email) > 160) {
    $errors[] = 'email';
}
if (mb_strlen($message) < 10 || mb_strlen($message) > MAX_MESSAGE) {
    $errors[] = 'message';
}

if ($errors !== []) {
    respond(false, 'Champs invalides : ' . implode(', ', $errors) . '.', 422);
}

// ── Envoi ────────────────────────────────────────────────────────────────
$expediteur = headerSafe($prenom . ' ' . $nom);
$replyTo    = headerSafe($email);

$corps = "Nouveau message depuis le portfolio\n"
       . str_repeat('-', 40) . "\n"
       . "Nom     : {$expediteur}\n"
       . "Email   : {$replyTo}\n"
       . 'Date    : ' . date('d/m/Y H:i:s') . "\n"
       . 'IP      : ' . ($_SERVER['REMOTE_ADDR'] ?? 'inconnue') . "\n"
       . str_repeat('-', 40) . "\n\n"
       . $message . "\n";

$headers = [
    'From: Portfolio <' . MAIL_FROM . '>',
    'Reply-To: ' . $expediteur . ' <' . $replyTo . '>',
    'Content-Type: text/plain; charset=UTF-8',
    'X-Mailer: PHP/' . PHP_VERSION,
];

$envoye = mail(
    MAIL_TO,
    '=?UTF-8?B?' . base64_encode(MAIL_SUBJECT) . '?=',
    $corps,
    implode("\r\n", $headers)
);

if (!$envoye) {
    error_log('[contact.php] échec de mail() pour ' . $replyTo);
    respond(false, 'L\'envoi a échoué. Écrivez-moi directement à ' . MAIL_TO . '.', 500);
}

$_SESSION['contact_last'] = $now;
respond(true, 'Message envoyé. Merci, je vous réponds rapidement.');
