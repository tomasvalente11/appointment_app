import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { api } from "../lib/api"

export default class extends Controller {
  static targets = [
    "modal", "steps",
    "step1", "step2", "step3", "success",
    "nutritionistSearch", "nutritionistId", "nutritionistSuggestions",
    "serviceField", "serviceSelect",
    "dateInput", "timeField", "timeSlots", "noSlots",
    "guestName", "guestEmail",
    "summaryBox", "formError", "submitBtn",
  ]

  connect() {
    this._availableDates = []
    this._calendar = null
    this._selectedTime = null
    this._services = []
  }

  disconnect() {
    this._calendar?.destroy()
  }

  // ─── Open / Close ──────────────────────────────────────────────

  open(event) {
    const btn = event.currentTarget
    const id = btn.dataset.nutritionistId
    const name = btn.dataset.nutritionistName
    const services = JSON.parse(btn.dataset.services || '[]')

    this._reset()
    this._setNutritionist(id, name, services)
    this.nutritionistSearchTarget.readOnly = true
    this.nutritionistSearchTarget.classList.add('bg-gray-50', 'cursor-default')
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  close() {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // ─── Step navigation ───────────────────────────────────────────

  goToStep1() { this._showStep(1) }

  goToStep2() {
    if (!this.nutritionistIdTarget.value) {
      this.nutritionistSearchTarget.classList.add('border-red-400')
      return
    }
    this._showStep(2)
    this._initCalendar()
  }

  goToStep3() {
    if (!this.dateInputTarget.value || !this._selectedTime) {
      if (!this.dateInputTarget.value) this.dateInputTarget.classList.add('border-red-400')
      return
    }
    this._buildSummary()
    this._showStep(3)
  }

  // ─── Nutritionist search ───────────────────────────────────────

  onNutritionistSearch() {
    const q = this.nutritionistSearchTarget.value.trim().toLowerCase()
    if (q.length < 1) {
      this.nutritionistSuggestionsTarget.classList.add('hidden')
      return
    }

    api.get(`/find?q=${encodeURIComponent(q)}&format=json`)
      .then(data => this._renderSuggestions(data))
      .catch(err => console.error('Nutritionist search failed:', err))
  }

  _renderSuggestions(nutritionists) {
    const box = this.nutritionistSuggestionsTarget
    box.innerHTML = ''
    if (!nutritionists.length) {
      box.classList.add('hidden')
      return
    }
    nutritionists.forEach(n => {
      const btn = document.createElement('button')
      btn.type = 'button'
      btn.className = 'hover:bg-gray-50 px-3 py-2 text-gray-700 text-left text-sm transition-colors w-full'
      btn.textContent = n.name
      btn.addEventListener('click', () => {
        this._setNutritionist(n.id, n.name, n.services)
        box.classList.add('hidden')
      })
      box.appendChild(btn)
    })
    box.classList.remove('hidden')
  }

  _setNutritionist(id, name, services) {
    this.nutritionistSearchTarget.value = name
    this.nutritionistIdTarget.value = id
    this._services = services
    this.nutritionistSearchTarget.classList.remove('border-red-400')
    this._renderServices(services)
    this._fetchAvailableDates(id)
  }

  _renderServices(services) {
    const select = this.serviceSelectTarget
    select.innerHTML = `<option value="">${window.I18n?.modal?.any_service ?? 'Any service'}</option>`
    services.forEach(s => {
      const opt = document.createElement('option')
      opt.value = s.id
      opt.textContent = `${s.name} (${s.duration} min)`
      select.appendChild(opt)
    })
    this.serviceFieldTarget.classList.toggle('hidden', services.length === 0)
  }

  // ─── Date & slots ─────────────────────────────────────────────

  _fetchAvailableDates(nutritionistId) {
    api.get(`/api/nutritionists/${nutritionistId}/available_dates`)
      .then(data => {
        this._availableDates = data.available_dates
        if (this._calendar) this._updateCalendarDates()
      })
      .catch(err => console.error('Failed to load available dates:', err))
  }

  _initCalendar() {
    if (this._calendar) {
      this._calendar.destroy()
      this._calendar = null
    }

    this._calendar = flatpickr(this.dateInputTarget, {
      allowInput: false,
      dateFormat: 'Y-m-d',
      disable: [date => !this._isAvailable(date)],
      inline: false,
      minDate: 'today',
      onDayCreate: (_dObj, _dStr, _fp, dayElem) => {
        const date = dayElem.dateObj
        const iso = this._toIso(date)
        if (this._availableDates.includes(iso)) {
          dayElem.classList.add('available-day')
        }
      },
      onChange: (_dates, dateStr) => {
        if (dateStr) this._fetchSlots(dateStr)
        else this._clearSlots()
      },
    })
  }

  _updateCalendarDates() {
    if (!this._calendar) return
    this._calendar.set('disable', [date => !this._isAvailable(date)])
    this._calendar.redraw()
  }

  _isAvailable(date) {
    return this._availableDates.includes(this._toIso(date))
  }

  _toIso(date) {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, '0')
    const d = String(date.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  onServiceChange() {
    if (this.dateInputTarget.value) this._fetchSlots(this.dateInputTarget.value)
  }

  _fetchSlots(date) {
    const nutritionistId = this.nutritionistIdTarget.value
    const serviceId = this.serviceSelectTarget.value

    let url = `/api/nutritionists/${nutritionistId}/available_slots?date=${date}`
    if (serviceId) url += `&service_id=${serviceId}`

    api.get(url)
      .then(data => this._renderSlots(data.slots))
      .catch(err => {
        console.error('Failed to load slots:', err)
        this._renderSlots([])
      })
  }

  _renderSlots(slots) {
    this._selectedTime = null
    const container = this.timeSlotsTarget
    container.innerHTML = ''

    if (!slots.length) {
      this.timeFieldTarget.classList.add('hidden')
      this.noSlotsTarget.classList.remove('hidden')
      return
    }

    this.noSlotsTarget.classList.add('hidden')
    this.timeFieldTarget.classList.remove('hidden')

    slots.forEach(time => {
      const btn = document.createElement('button')
      btn.type = 'button'
      btn.className = 'border border-gray-300 hover:border-green-500 hover:text-green-700 py-1.5 rounded-lg text-gray-700 text-sm transition-colors'
      btn.textContent = time
      btn.dataset.time = time
      btn.addEventListener('click', () => this._selectTime(btn, time))
      container.appendChild(btn)
    })
  }

  _selectTime(btn, time) {
    this.timeSlotsTarget.querySelectorAll('button').forEach(b => {
      b.classList.remove('bg-green-600', 'border-green-600', 'text-white')
    })
    btn.classList.add('bg-green-600', 'border-green-600', 'text-white')
    this._selectedTime = time
  }

  _clearSlots() {
    this.timeSlotsTarget.innerHTML = ''
    this.timeFieldTarget.classList.add('hidden')
    this.noSlotsTarget.classList.add('hidden')
    this._selectedTime = null
  }

  // ─── Summary & submit ─────────────────────────────────────────

  _buildSummary() {
    const m = window.I18n?.modal ?? {}
    const service = this._services.find(s => s.id == this.serviceSelectTarget.value)
    const lines = [
      `<div><span class="text-gray-400">${m.summary_nutritionist ?? 'Nutritionist:'}</span> ${this.nutritionistSearchTarget.value}</div>`,
      service ? `<div><span class="text-gray-400">${m.summary_service ?? 'Service:'}</span> ${service.name}</div>` : '',
      `<div><span class="text-gray-400">${m.summary_date ?? 'Date:'}</span> ${this.dateInputTarget.value}</div>`,
      `<div><span class="text-gray-400">${m.summary_time ?? 'Time:'}</span> ${this._selectedTime}</div>`,
    ]
    this.summaryBoxTarget.innerHTML = lines.filter(Boolean).join('')
  }

  submit() {
    const name = this.guestNameTarget.value.trim()
    const email = this.guestEmailTarget.value.trim()

    if (!name || !email) {
      this.formErrorTarget.textContent = window.I18n?.modal?.fill_name_email ?? 'Please fill in your name and email.'
      this.formErrorTarget.classList.remove('hidden')
      return
    }

    const serviceId = this.serviceSelectTarget.value
    const requestedAt = `${this.dateInputTarget.value}T${this._selectedTime}:00`

    const body = {
      appointment_request: {
        guest_email: email,
        guest_name: name,
        nutritionist_id: this.nutritionistIdTarget.value,
        requested_at: requestedAt,
        service_id: serviceId || null,
      },
    }

    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = window.I18n?.modal?.btn_sending ?? 'Sending...'

    api.post('/api/appointment_requests', body)
      .then(() => this._showSuccess())
      .catch(err => {
        this.formErrorTarget.textContent = err.message
        this.formErrorTarget.classList.remove('hidden')
        this.submitBtnTarget.disabled = false
        this.submitBtnTarget.textContent = window.I18n?.modal?.btn_confirm ?? 'Confirm'
      })
  }

  // ─── Helpers ──────────────────────────────────────────────────

  _showStep(n) {
    ;[1, 2, 3].forEach(i => {
      this[`step${i}Target`].classList.toggle('hidden', i !== n)
    })
    this.stepsTarget.querySelectorAll('[data-step]').forEach(el => {
      const active = parseInt(el.dataset.step) === n
      el.classList.toggle('font-medium', active)
      el.classList.toggle('text-[#3aaa93]', active)
      el.classList.toggle('text-gray-400', !active)
    })
  }

  _showSuccess() {
    ;[1, 2, 3].forEach(i => this[`step${i}Target`].classList.add('hidden'))
    this.successTarget.classList.remove('hidden')
  }

  _reset() {
    this.nutritionistSearchTarget.value = ''
    this.nutritionistSearchTarget.readOnly = false
    this.nutritionistSearchTarget.classList.remove('bg-gray-50', 'cursor-default')
    this.nutritionistIdTarget.value = ''
    this.nutritionistSuggestionsTarget.classList.add('hidden')
    this.serviceSelectTarget.innerHTML = `<option value="">${window.I18n?.modal?.any_service ?? 'Any service'}</option>`
    this.serviceFieldTarget.classList.add('hidden')
    this._calendar?.destroy()
    this._calendar = null
    this.dateInputTarget.value = ''
    this._clearSlots()
    this.guestNameTarget.value = ''
    this.guestEmailTarget.value = ''
    this.formErrorTarget.classList.add('hidden')
    this.submitBtnTarget.disabled = false
    this.submitBtnTarget.textContent = window.I18n?.modal?.btn_confirm ?? 'Confirm'
    this.successTarget.classList.add('hidden')
    this._availableDates = []
    this._selectedTime = null
    this._showStep(1)
  }
}
