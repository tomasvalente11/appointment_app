import AppointmentRequests from './components/AppointmentRequests'
import { createRoot } from 'react-dom/client'

let root = null

function mount() {
  const container = document.getElementById('requests-app')
  if (!container) {
    if (root) {
      root.unmount()
      root = null
    }
    return
  }
  const nutritionistId = parseInt(container.dataset.nutritionistId, 10)
  if (!root) root = createRoot(container)
  root.render(<AppointmentRequests nutritionistId={nutritionistId} />)
}

document.addEventListener('turbo:load', mount)
mount()
