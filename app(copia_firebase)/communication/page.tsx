
'use client';

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Mail, MessageSquare, Send, Users, Wand2, ArrowRight, Inbox } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Separator } from '@/components/ui/separator';

const directMessages: any[] = []
const activeClasses: any[] = [];


export default function CommunicationPage() {
  
  return (
    <div className="flex flex-col gap-8">
      <h1 className="font-headline text-3xl font-semibold">Comunicación</h1>

      <Tabs defaultValue="inbox">
        <TabsList className="grid w-full grid-cols-3">
           <TabsTrigger value="inbox">
             <Inbox className="mr-2 h-4 w-4" /> Inbox
          </TabsTrigger>
          <TabsTrigger value="class-forums">
             <MessageSquare className="mr-2 h-4 w-4" /> Foros de Clase
          </TabsTrigger>
          <TabsTrigger value="campaign">
            <Mail className="mr-2 h-4 w-4" /> Campañas de Email
          </TabsTrigger>
        </TabsList>

        <TabsContent value="inbox">
            <Card>
                <CardHeader>
                    <CardTitle>Inbox</CardTitle>
                    <CardDescription>Conversaciones directas con tus estudiantes.</CardDescription>
                </CardHeader>
                <CardContent className="space-y-2 p-0">
                   {directMessages.length > 0 ? directMessages.map((message, index) => (
                       <div key={message.id}>
                            <div className="flex items-center gap-4 p-4 hover:bg-muted/50 cursor-pointer">
                                {/* Avatar logic here */}
                                <div className="flex-1">
                                    <div className="flex items-baseline justify-between">
                                        <p className="font-semibold">{message.studentName}</p>
                                        <p className="text-xs text-muted-foreground">{message.timestamp}</p>
                                    </div>
                                    <p className="text-sm text-muted-foreground truncate">{message.lastMessage}</p>
                                </div>
                                {message.unread && (
                                    <div className="h-2 w-2 rounded-full bg-primary shrink-0"></div>
                                )}
                            </div>
                           {index < directMessages.length - 1 && <Separator />}
                       </div>
                   )) : (
                    <div className="flex h-64 items-center justify-center rounded-lg border-2 border-dashed m-6">
                        <div className="text-center text-muted-foreground">
                            <Inbox className="mx-auto h-12 w-12" />
                            <p className="mt-4 font-semibold">
                                Tu bandeja de entrada está vacía
                            </p>
                            <p className="mt-1 text-sm">
                                Las conversaciones con tus estudiantes aparecerán aquí.
                            </p>
                        </div>
                    </div>
                   )}
                </CardContent>
            </Card>
        </TabsContent>
        
        <TabsContent value="class-forums">
            <Card>
                <CardHeader>
                    <CardTitle>Foros de Clase</CardTitle>
                    <CardDescription>Comunícate con los estudiantes de cada una de tus clases activas.</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    {activeClasses.length > 0 ? (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                            {activeClasses.map(cls => (
                                <Card key={cls.id} className="flex flex-col">
                                    {/* Class forum card logic here */}
                                </Card>
                            ))}
                        </div>
                    ) : (
                        <div className="flex h-64 items-center justify-center rounded-lg border-2 border-dashed">
                            <div className="text-center text-muted-foreground">
                                <MessageSquare className="mx-auto h-12 w-12" />
                                <p className="mt-4 font-semibold">
                                    No tienes clases activas
                                </p>
                                <p className="mt-1 text-sm">
                                    Crea una clase para empezar a comunicarte con tus estudiantes.
                                </p>
                            </div>
                        </div>
                    )}
                </CardContent>
            </Card>
        </TabsContent>
        
        <TabsContent value="campaign">
          <Card>
            <CardHeader>
              <CardTitle>Campañas de Email</CardTitle>
              <CardDescription>
                Envía anuncios, promociones o noticias a todos tus estudiantes con un solo clic.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                <div className="space-y-2">
                    <label htmlFor="audience" className="font-medium text-sm">Destinatarios</label>
                    <div className="flex items-center gap-2 p-3 rounded-md bg-muted">
                        <Users className="h-5 w-5 text-muted-foreground" />
                        <span className="font-semibold">Todos los estudiantes (0)</span>
                    </div>
                </div>

                <div className="space-y-2">
                    <label htmlFor="subject" className="font-medium text-sm">Asunto</label>
                    <Input id="subject" placeholder="Ej: ¡Nuevas clases de verano!" />
                </div>
                
                 <div className="space-y-2">
                    <label htmlFor="body" className="font-medium text-sm">Contenido del Correo</label>
                    <Textarea id="body" placeholder="Escribe tu mensaje aquí..." rows={8} className="resize-y" />
                </div>
                
                <div className="flex justify-between items-center">
                    <Button variant="outline">
                        <Wand2 className="mr-2 h-4 w-4" />
                        Generar con IA
                    </Button>
                    <Button>
                        <Send className="mr-2 h-4 w-4" />
                        Enviar Campaña
                    </Button>
                </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
