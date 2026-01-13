
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useAuth, useUser } from '@/firebase';
import { initiateGoogleSignIn } from '@/firebase/auth';
import { Loader2 } from 'lucide-react';
import AppShell from '@/components/AppShell';

const GoogleIcon = (props: React.SVGProps<SVGSVGElement>) => (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="24px" height="24px" {...props}>
        <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24s8.955,20,20,20s20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z" />
        <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z" />
        <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.222,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z" />
        <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.574l6.19,5.238C39.901,35.639,44,30.138,44,24C44,22.659,43.862,21.35,43.611,20.083z" />
    </svg>
);

const PladsProLogo = () => (
    <div className="flex items-center gap-2">
        <div className="p-0">
            <svg
                width="48"
                height="48"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
            >
                <rect width="24" height="24" rx="6" fill="hsl(var(--brand-purple))" />
                <path
                    d="M12.5 5C13.3284 5 14 5.67157 14 6.5C14 7.32843 13.3284 8 12.5 8C11.6716 8 11 7.32843 11 6.5C11 5.67157 11.6716 5 12.5 5ZM9.3 19L11 15.65L14 9H9V11H12.5L10.3 15.65L11.5 18L15 11H17L11.5 22L9.3 19Z"
                    fill="hsl(var(--brand-green))"
                />
            </svg>
        </div>
        <span className="font-headline text-3xl font-bold text-foreground">
            Plads Pro
        </span>
    </div>
);


const LoginPageContent = () => {
    const auth = useAuth();
    const { user, isUserLoading } = useUser();
    const router = useRouter();

    useEffect(() => {
        if (!isUserLoading && user) {
            router.replace('/');
        }
    }, [user, isUserLoading, router]);

    const handleLogin = () => {
        if (auth) {
            initiateGoogleSignIn(auth);
        }
    };

    if (isUserLoading || user) {
        return (
            <div className="flex h-screen w-screen items-center justify-center bg-background">
                <Loader2 className="h-12 w-12 animate-spin text-primary" />
            </div>
        );
    }

    return (
        <div className="flex h-screen w-screen items-center justify-center bg-gradient-to-br from-brand-purple to-brand-green p-4">
            <Card className="w-full max-w-md shadow-2xl animate-fade-in-up">
                <CardHeader className="text-center space-y-4 pt-8">
                    <div className="flex justify-center">
                        <PladsProLogo />
                    </div>
                    <CardTitle className="font-headline text-2xl tracking-tight">Bienvenid@ a Plads Pro</CardTitle>
                    <CardDescription className="text-muted-foreground !mt-2">
                        Conecta a quienes quieren aprender con quienes aman enseñar.
                    </CardDescription>
                </CardHeader>
                <CardContent className="p-8">
                    <Button onClick={handleLogin} className="w-full h-12 text-base">
                        <GoogleIcon className="mr-3" />
                        Ingresar con Google
                    </Button>
                </CardContent>
            </Card>
        </div>
    );
};

export default function LoginPage() {
    const { user, isUserLoading } = useUser();

    if (isUserLoading) {
        return (
            <div className="flex h-screen w-screen items-center justify-center">
                <Loader2 className="h-12 w-12 animate-spin text-primary" />
            </div>
        );
    }

    if (user) {
        return <LoginPageContent />;
    }

    return <LoginPageContent />;
}

