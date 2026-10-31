import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actorId"]

  submit() {
    this.element.requestSubmit()
  }

  clearActorId() {
    this.actorIdTarget.value = ""
  }
}
