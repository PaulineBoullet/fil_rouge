import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Pilote la fenêtre modale du layout (#app-modal).
// - open  : un formulaire vient d'être chargé dans le cadre "modal" -> on affiche la fenêtre
// - close : après un enregistrement réussi, le serveur redirige vers une page qui ne contient
//           pas le cadre ; on ferme la fenêtre et on recharge la page entière
// - clear : la fenêtre est fermée -> on vide le cadre pour la prochaine ouverture
export default class extends Controller {
  open() {
    if (this.frame.innerHTML.trim() === "") return
    this.bootstrapModal.show()
  }

  close(event) {
    event.preventDefault()
    this.bootstrapModal.hide()
    Turbo.visit(event.detail.response.url)
  }

  clear() {
    this.frame.removeAttribute("src")
    this.frame.innerHTML = ""
  }

  get frame() {
    return this.element.querySelector("turbo-frame#modal")
  }

  get bootstrapModal() {
    return window.bootstrap.Modal.getOrCreateInstance(this.element)
  }
}
