import { Controller } from "@hotwired/stimulus"

// Envoie le formulaire dès qu'un filtre change (liste déroulante, case à cocher).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
