import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Remplace la boîte de dialogue du navigateur utilisée par data-turbo-confirm
// par la fenêtre #confirm-modal du layout.
export default class extends Controller {
  static targets = ["message"]

  connect() {
    const confirmMethod = (message) => this.ask(message)
    if (Turbo.config?.forms) {
      Turbo.config.forms.confirm = confirmMethod   // Turbo 8 récent
    } else {
      Turbo.setConfirmMethod(confirmMethod)        // versions antérieures
    }
  }

  // Affiche la fenêtre et renvoie une promesse : true si l'on clique sur « Supprimer »,
  // false si la fenêtre est fermée autrement (Annuler, croix, Échap).
  ask(message) {
    this.messageTarget.textContent = message
    this.accepted = false

    return new Promise((resolve) => {
      this.element.addEventListener("hidden.bs.modal", () => resolve(this.accepted), { once: true })
      this.bootstrapModal.show()
    })
  }

  accept() {
    this.accepted = true
    this.bootstrapModal.hide()
  }

  get bootstrapModal() {
    return window.bootstrap.Modal.getOrCreateInstance(this.element)
  }
}
