import { Controller } from "@hotwired/stimulus"

// Mon domaine : une pastille de couleur proposée remplit le sélecteur de couleur du thème.
export default class extends Controller {
  pick(event) {
    const input = this.element.querySelector("input[type=color]")
    if (input) input.value = event.target.value
  }
}
