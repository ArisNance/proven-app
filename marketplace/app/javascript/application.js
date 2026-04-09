import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import "./channels"
import "./mountReact"
import CatalogFiltersController from "./controllers/catalog_filters_controller"
import ConversationController from "./controllers/conversation_controller"
import FlashController from "./controllers/flash_controller"
import FormStateController from "./controllers/form_state_controller"
import MicroMotionController from "./controllers/micro_motion_controller"
import VerificationModalController from "./controllers/verification_modal_controller"

window.Stimulus = Application.start()
Stimulus.register("catalog-filters", CatalogFiltersController)
Stimulus.register("conversation", ConversationController)
Stimulus.register("flash", FlashController)
Stimulus.register("form-state", FormStateController)
Stimulus.register("micro-motion", MicroMotionController)
Stimulus.register("verification-modal", VerificationModalController)
