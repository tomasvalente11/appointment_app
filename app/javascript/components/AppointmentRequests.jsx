import EmptyState from './EmptyState'
import PropTypes from 'prop-types'
import RequestCard from './RequestCard'
import Toast from './Toast'
import { api } from '../lib/api'
import { useEffect, useState } from 'react'

const FILTER_KEYS = ['all', 'pending', 'answered']

export default function AppointmentRequests({ nutritionistId }) {
  const r = window.I18n?.requests ?? {}
  const [error, setError] = useState(null)
  const [filter, setFilter] = useState('pending')
  const [loading, setLoading] = useState(true)
  const [requests, setRequests] = useState([])
  const [toast, setToast] = useState(null)

  useEffect(() => {
    api.get(`/api/nutritionists/${nutritionistId}/appointment_requests`)
      .then(data => { setRequests(data); setLoading(false) })
      .catch(() => { setError(r.error ?? 'Failed to load requests.'); setLoading(false) })
  }, [nutritionistId])

  function handleUpdate(requestId, newStatus, rejectionNote = null) {
    setRequests(prev => prev.map(req =>
      req.id === requestId ? { ...req, status: newStatus, rejection_note: rejectionNote } : req
    ))
    setToast({
      message: newStatus === 'accepted'
        ? (r.toast?.accepted ?? 'Request accepted, guest notified by email.')
        : (r.toast?.rejected ?? 'Request rejected, guest notified by email.'),
      status: newStatus,
    })
  }

  const filtered = requests.filter(req => {
    if (filter === 'pending') return req.status === 'pending'
    if (filter === 'answered') return req.status !== 'pending'
    return true
  })

  if (loading) {
    return <div className='py-20 text-center text-gray-400 text-sm'>{r.loading ?? 'Loading...'}</div>
  }

  if (error) {
    return <div className='py-20 text-center text-red-500 text-sm'>{error}</div>
  }

  return (
    <div>
      <div className='mb-6'>
        <h2 className='text-xl font-bold text-gray-900'>{r.heading ?? 'Appointment Requests'}</h2>
        <p className='text-sm text-gray-400 mt-0.5'>{r.subheading ?? 'Accept or reject new pending requests'}</p>
      </div>

      <div className='flex gap-2 mb-6'>
        {FILTER_KEYS.map(f => (
          <button
            className={`font-medium px-4 py-1.5 rounded-full text-sm transition-colors ${
              filter === f
                ? 'bg-[#3aaa93] text-white'
                : 'border border-gray-300 text-gray-600 hover:border-gray-400'
            }`}
            key={f}
            onClick={() => setFilter(f)}
          >
            {r.filters?.[f] ?? f}
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <EmptyState filter={filter} />
      ) : (
        <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4'>
          {filtered.map(req => (
            <RequestCard
              guestEmail={req.guest_email}
              guestName={req.guest_name}
              key={req.id}
              nutritionistId={nutritionistId}
              onUpdate={handleUpdate}
              rejectionNote={req.rejection_note}
              requestedAt={req.requested_at}
              requestId={req.id}
              service={req.service}
              status={req.status}
            />
          ))}
        </div>
      )}

      {toast && (
        <Toast
          message={toast.message}
          onDismiss={() => setToast(null)}
          status={toast.status}
        />
      )}
    </div>
  )
}

AppointmentRequests.propTypes = {
  nutritionistId: PropTypes.number.isRequired,
}
