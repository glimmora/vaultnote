import { useEffect } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useCryptoStore } from './store/cryptoStore'
import UnlockScreen from './presentation/screens/UnlockScreen'
import SetupScreen from './presentation/screens/SetupScreen'
import HomeScreen from './presentation/screens/HomeScreen'
import NoteEditorScreen from './presentation/screens/NoteEditorScreen'
import LabelScreen from './presentation/screens/LabelScreen'
import QRExportScreen from './presentation/screens/QRExportScreen'
import QRImportScreen from './presentation/screens/QRImportScreen'
import SettingsScreen from './presentation/screens/SettingsScreen'

function App() {
  const isUnlocked = useCryptoStore((state) => state.isUnlocked)
  const isInitialized = useCryptoStore((state) => state.isInitialized)
  const resetAutoLockTimer = useCryptoStore((state) => state.resetAutoLockTimer)

  // Reset auto-lock timer on user activity
  useEffect(() => {
    if (!isUnlocked) return

    const handleActivity = () => {
      resetAutoLockTimer()
    }

    // Listen for user activity events
    const events = ['mousedown', 'keydown', 'scroll', 'touchstart']
    events.forEach(event => {
      window.addEventListener(event, handleActivity)
    })

    return () => {
      events.forEach(event => {
        window.removeEventListener(event, handleActivity)
      })
    }
  }, [isUnlocked, resetAutoLockTimer])

  if (!isInitialized) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route
          path="/"
          element={isUnlocked ? <HomeScreen /> : <UnlockScreen />}
        />
        <Route
          path="/setup"
          element={<SetupScreen />}
        />
        <Route
          path="/note/new"
          element={isUnlocked ? <NoteEditorScreen /> : <Navigate to="/" />}
        />
        <Route
          path="/note/:id"
          element={isUnlocked ? <NoteEditorScreen /> : <Navigate to="/" />}
        />
        <Route
          path="/labels"
          element={isUnlocked ? <LabelScreen /> : <Navigate to="/" />}
        />
        <Route
          path="/qr-export/:id"
          element={isUnlocked ? <QRExportScreen /> : <Navigate to="/" />}
        />
        <Route
          path="/qr-import"
          element={isUnlocked ? <QRImportScreen /> : <Navigate to="/" />}
        />
        <Route
          path="/settings"
          element={isUnlocked ? <SettingsScreen /> : <Navigate to="/" />}
        />
      </Routes>
    </BrowserRouter>
  )
}

export default App
