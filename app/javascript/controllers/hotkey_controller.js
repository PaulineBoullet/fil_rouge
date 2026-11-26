import { Controller } from "@hotwired/stimulus"

// ⌘K ou Ctrl+K : place le curseur dans le champ de recherche de la barre du haut.
export default class extends Controller {
  static targets = ["input"]

  focus(event) {
    event.preventDefault()
    this.inputTarget.focus()
    this.inputTarget.select()
  }
}
