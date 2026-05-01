import PropTypes from 'prop-types'
import { useState } from 'react'
import { api } from '../lib/api'

export default function ActionButtons({ nutritionistId, onUpdate, requestId, status }) {
  const a = window.I18n?.requests?.action ?? {}
  const [expanded, setExpanded] = useState(false)
  const [loading, setLoading] = useState(false)
  const [rejecting, setRejecting] = useState(false)
  const [note, setNote] = useState('')
  const [errorMsg, setErrorMsg] = useState(null)

  if (status !== 'pending') return null

  function handle(newStatus, rejectionNote) {
    setLoading(true)
    setErrorMsg(null)
    api.patch(`/api/appointment_requests/${requestId}`, {
      appointment_request: {
        nutritionist_id: nutritionistId,
        rejection_note: rejectionNote || null,
        status: newStatus,
      },
    })
      .then(() => {
        onUpdate(requestId, newStatus, rejectionNote || null)
        setRejecting(false)
        setNote('')
      })
      .catch(err => {
        setErrorMsg(err.message || 'Something went wrong. Please try again.')
        setLoading(false)
      })
  }

  return (
    <>
      {!expanded ? (
        <button
          className='text-[#3aaa93] font-medium text-sm hover:underline'
          onClick={() => setExpanded(true)}
        >
          {a.answer_request ?? 'Answer request'}
        </button>
      ) : (
      <div className='flex flex-col gap-2'>
        <div className='flex gap-2'>
          <button
            className='bg-[#3aaa93] disabled:opacity-50 font-medium hover:bg-[#2d9281] px-3 py-1.5 rounded-lg text-sm text-white transition-colors'
            disabled={loading}
            onClick={() => handle('accepted')}
          >
            {a.accept ?? 'Accept'}
          </button>
          <button
            className='border border-gray-300 disabled:opacity-50 font-medium hover:border-red-400 hover:text-red-600 px-3 py-1.5 rounded-lg text-gray-700 text-sm transition-colors'
            disabled={loading}
            onClick={() => setRejecting(true)}
          >
            {a.reject ?? 'Reject'}
          </button>
        </div>
        {errorMsg && (
          <p className='text-red-500 text-xs'>{errorMsg}</p>
        )}
      </div>
      )}

      {rejecting && (
        <div className='fixed inset-0 z-50 flex items-center justify-center p-4'>
          <div className='absolute inset-0 bg-black/50' onClick={() => { setRejecting(false); setNote(''); setErrorMsg(null) }} />
          <div className='bg-white relative rounded-2xl shadow-xl w-full max-w-sm p-6'>
            <h3 className='font-semibold text-gray-900 text-lg mb-1'>{a.reject_heading ?? 'Reject request'}</h3>
            <p className='text-gray-500 text-sm mb-4'>{a.reject_hint ?? 'Optionally provide a reason. It will be included in the email sent to the guest.'}</p>
            <textarea
              autoFocus
              className='border border-gray-300 focus:outline-none focus:ring-2 focus:ring-red-400 px-3 py-2 resize-none rounded-lg text-gray-700 text-sm w-full'
              onChange={e => setNote(e.target.value)}
              placeholder={a.reject_placeholder ?? 'e.g. Slot no longer available, please reschedule.'}
              rows={3}
              value={note}
            />
            {errorMsg && (
              <p className='text-red-500 text-xs mt-2'>{errorMsg}</p>
            )}
            <div className='flex gap-3 mt-4'>
              <button
                className='border border-gray-300 disabled:opacity-50 flex-1 font-medium hover:border-gray-400 py-2.5 rounded-lg text-gray-700 text-sm transition-colors'
                disabled={loading}
                onClick={() => { setRejecting(false); setNote(''); setErrorMsg(null) }}
              >
                {a.cancel ?? 'Cancel'}
              </button>
              <button
                className='bg-red-600 disabled:opacity-50 flex-1 font-medium hover:bg-red-700 py-2.5 rounded-lg text-sm text-white transition-colors'
                disabled={loading}
                onClick={() => handle('rejected', note)}
              >
                {a.confirm_rejection ?? 'Confirm rejection'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}

ActionButtons.propTypes = {
  nutritionistId: PropTypes.number.isRequired,
  onUpdate: PropTypes.func.isRequired,
  requestId: PropTypes.number.isRequired,
  status: PropTypes.string.isRequired,
}
